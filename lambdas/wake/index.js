// wake/index.js
const { EC2Client, DescribeInstancesCommand, StartInstancesCommand } = require("@aws-sdk/client-ec2");
const { SSMClient, PutParameterCommand } = require("@aws-sdk/client-ssm");

const REGION = process.env.AWS_REGION || "us-east-1";
const INSTANCE_ID = (process.env.INSTANCE_ID || "").trim();
const SSM_PARAM = (process.env.SSM_PARAM_LAST_WAKE || "").trim();

const ec2 = new EC2Client({ region: REGION });
const ssm = new SSMClient({ region: REGION });

const CORS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Authorization"
};

function wrap(event, payload, statusCode = 200) {
  const isApiGw = event && (event.version === "2.0" || "rawPath" in event);
  return isApiGw
    ? { statusCode, headers: CORS, body: JSON.stringify(payload) }
    : payload;
}

async function touchLastWake() {
  if (!SSM_PARAM) return;
  const ts = Math.floor(Date.now() / 1000).toString();
  await ssm.send(new PutParameterCommand({
    Name: SSM_PARAM,
    Value: ts,
    Type: "String",
    Overwrite: true
  }));
}

async function getState(instanceId) {
  const d = await ec2.send(new DescribeInstancesCommand({ InstanceIds: [instanceId] }));
  const inst = d?.Reservations?.[0]?.Instances?.[0];
  return inst?.State?.Name || "unknown";
}

exports.handler = async (event = {}) => {
  if (event?.requestContext?.http?.method === "OPTIONS") {
    return wrap(event, { ok: true }, 204);
  }

  if (!INSTANCE_ID) {
    return wrap(event, { ok: false, error: "Missing INSTANCE_ID" }, 500);
  }

  try {
    const state = await getState(INSTANCE_ID);

    if (state === "running" || state === "pending") {
      await touchLastWake();
      return wrap(event, { ok: true, action: "noop", instanceId: INSTANCE_ID, state }, 200);
    }

    if (state === "stopping" || state === "shutting-down") {
      // Не стартуем, пока идёт остановка/удаление
      return wrap(event, { ok: true, action: "busy", instanceId: INSTANCE_ID, state }, 202);
    }

    if (state === "stopped") {
      await ec2.send(new StartInstancesCommand({ InstanceIds: [INSTANCE_ID] }));
      await touchLastWake();
      return wrap(event, { ok: true, action: "wake", instanceId: INSTANCE_ID, state: "pending" }, 202);
    }

    return wrap(event, { ok: false, instanceId: INSTANCE_ID, state, error: "not-startable" }, 400);
  } catch (err) {
    return wrap(event, { ok: false, error: String(err) }, 500);
  }
};