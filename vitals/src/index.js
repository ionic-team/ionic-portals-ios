import { onFCP } from "web-vitals";

onFCP(report => window.webkit.messageHandlers.vitals.postMessage({ name: report.name, value: report.value, portalName: window.portalInitialContext?.name }));
