import { get } from "../api.js";

function appStatus(health, sync) {
  if (health === "Degraded") return "error";
  if (health === "Progressing" || sync === "OutOfSync") return "warn";
  if (health === "Healthy" && sync === "Synced") return "ok";
  return "unknown";
}

export function argoCDApps() {
  return {
    key: "/api/argocd/apps#apps",
    staleTime: 30,
    async fetch() {
      const res = await get("/api/argocd/apps");
      return {
        items: res.data.map((app) => ({
          name: app.name,
          status: appStatus(app.health_status, app.sync_status),
          meta: `${app.health_status} · ${app.sync_status}`,
        })),
      };
    },
  };
}

export function argoCDResources() {
  return {
    key: "/api/argocd/apps#resources",
    staleTime: 30,
    async fetch() {
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
    },
  };
}
