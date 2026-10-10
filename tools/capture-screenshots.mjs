import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const debuggerUrl = process.env.EDGE_DEBUGGER_URL ?? "http://127.0.0.1:9222";
const appUrl = process.env.GYM_APP_URL ?? "http://localhost:5195";
const outputDirectory = resolve("deliverables", "assets");

await mkdir(outputDirectory, { recursive: true });

const targetResponse = await fetch(
    `${debuggerUrl}/json/new?${encodeURIComponent(`${appUrl}/account/login`)}`,
    { method: "PUT" });

if (!targetResponse.ok) {
    throw new Error(`Không tạo được Edge target: HTTP ${targetResponse.status}.`);
}

const target = await targetResponse.json();
const socket = new WebSocket(target.webSocketDebuggerUrl);
const pending = new Map();
let sequence = 0;

socket.addEventListener("message", event => {
    const message = JSON.parse(event.data);
    if (!message.id || !pending.has(message.id)) {
        return;
    }

    const { resolve: complete, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) {
        reject(new Error(message.error.message));
    } else {
        complete(message.result);
    }
});

await new Promise((complete, reject) => {
    socket.addEventListener("open", complete, { once: true });
    socket.addEventListener("error", reject, { once: true });
});

function command(method, params = {}) {
    const id = ++sequence;
    const response = new Promise((complete, reject) => {
        pending.set(id, { resolve: complete, reject });
    });
    socket.send(JSON.stringify({ id, method, params }));
    return response;
}

const delay = milliseconds => new Promise(complete => setTimeout(complete, milliseconds));

async function navigate(path) {
    await command("Page.navigate", { url: `${appUrl}${path}` });
    await delay(1200);
}

async function screenshot(fileName) {
    const result = await command("Page.captureScreenshot", {
        format: "png",
        captureBeyondViewport: false,
        fromSurface: true
    });
    await writeFile(resolve(outputDirectory, fileName), Buffer.from(result.data, "base64"));
}

await command("Page.enable");
await command("Runtime.enable");
await command("Emulation.setDeviceMetricsOverride", {
    width: 1440,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false
});

await navigate("/account/login");
await screenshot("01-login.png");

await command("Runtime.evaluate", {
    expression: `(() => {
        document.querySelector('#Username').value = 'admin';
        document.querySelector('#Password').value = 'Admin@123';
        document.querySelector('form').submit();
    })()`
});
await delay(1800);

const pages = [
    ["/", "02-dashboard.png"],
    ["/Members", "03-members.png"],
    ["/Memberships", "04-memberships.png"],
    ["/Operations", "05-operations.png"],
    ["/Reports?type=revenue", "06-revenue-report.png"]
];

for (const [path, fileName] of pages) {
    await navigate(path);
    await screenshot(fileName);
}

socket.close();
console.log(`Đã tạo ${pages.length + 1} ảnh tại ${outputDirectory}.`);
