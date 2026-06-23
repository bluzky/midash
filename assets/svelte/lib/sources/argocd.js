import { get } from "../api.js";

function appStatus(health, sync) {
  if (health === "Degraded") return "error";
  if (health === "Progressing" || sync === "OutOfSync") return "warn";
  if (health === "Healthy" && sync === "Synced") return "ok";
  return "unknown";
}

// Top-level app health grid
export function argoCDApps() {
  return async () => {
    const res = await get("/api/argocd/apps");
    return {
      items: res.data.map((app) => ({
        name: app.name,
        status: appStatus(app.health_status, app.sync_status),
        meta: `${app.health_status} · ${app.sync_status}`,
      })),
    };
  };
}

// Flat list of all resources across all apps (for detailed view)
export function argoCDResources() {
  return async () => {
    const res = await get("/api/argocd/apps");
    const items = res.data.flatMap((app) =>
      (app.resources ?? []).map((r) => ({
        name: r.name,
        status: appStatus(r.health_status, null),
        subtitle: app.name,
        meta: r.health_status,
      })),
    );
    return { items };
  };
}
