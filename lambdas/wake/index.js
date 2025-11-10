const { EC2Client, DescribeInstancesCommand, StartInstancesCommand } = require("@aws-sdk/client-ec2");
const { SSMClient, PutParameterCommand } = require("@aws-sdk/client-ssm");

const ec2 = new EC2Client({ region: process.env.AWS_REGION || "us-east-1" });
const ssm = new SSMClient({ region: process.env.AWS_REGION || "us-east-1" });

const INSTANCE_ID = process.env.INSTANCE_ID;
const SSM_PARAM   = process.env.SSM_PARAM_LAST_WAKE;

function wrap(event, payload, statusCode = 200) {
  const isApiGw = event && (event.version === "2.0" || event.rawPath);
  return isApiGw
    ? { statusCode, headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }
    : payload;
}

async function touchLastWake() {
  if (!SSM_PARAM) return;
  const ts = Math.floor(Date.now() / 1000).toString();
  await ssm.send(new PutParameterCommand({ Name: SSM_PARAM, Value: ts, Type: "String", Overwrite: true }));
}

exports.handler = async (event = {}) => {
  if (!INSTANCE_ID) return wrap(event, { ok: false, error: "Missing INSTANCE_ID" }, 500);

  const d = await ec2.send(new DescribeInstancesCommand({ InstanceIds: [INSTANCE_ID] }));
  const state = d?.Reservations?.[0]?.Instances?.[0]?.State?.Name || "unknown";


  await touchLastWake();

  if (state === "running" || state === "pending") {
    return wrap(event, { ok: true, action: "noop", instanceId: INSTANCE_ID, state });
  }
  if (state === "stopping" || state === "shutting-down") {
    return wrap(event, { ok: true, action: "busy", instanceId: INSTANCE_ID, state }, 202);
  }
  if (state === "stopped") {
    await ec2.send(new StartInstancesCommand({ InstanceIds: [INSTANCE_ID] }));
    return wrap(event, { ok: true, action: "wake", instanceId: INSTANCE_ID, state: "pending" }, 202);
  }
  return wrap(event, { ok: false, instanceId: INSTANCE_ID, state, error: "not-startable" }, 400);
};