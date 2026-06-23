const CLICKUP_FIELDS = [
  { key: "CLICKUP_TOKEN", label: "ClickUp token", secret: true },
  { key: "CLICKUP_TEAM_ID", label: "ClickUp team ID" },
  { key: "CLICKUP_USER_ID", label: "ClickUp user ID" },
];

const ARGOCD_FIELDS = [
  {
    key: "ARGOCD_URL",
    label: "ArgoCD URL",
    placeholder: "https://argocd.example.com",
  },
  { key: "ARGOCD_TOKEN", label: "ArgoCD token", secret: true },
];

const GITHUB_FIELDS = [
  { key: "GITHUB_TOKEN", label: "GitHub token", secret: true },
  { key: "GITHUB_USERNAME", label: "GitHub username" },
];

const SENTRY_FIELDS = [
  { key: "SENTRY_TOKEN", label: "Sentry token", secret: true },
  {
    key: "SENTRY_PROJECTS",
    label: "Sentry projects",
    multiline: true,
    placeholder: "org/project:prod:staging",
    help: "Format: org/project:env1:env2,org2/project2:prod",
  },
];

export const CONFIG_GROUPS = {
  ARGOCD_TOKEN: ARGOCD_FIELDS,
  ARGOCD_URL: ARGOCD_FIELDS,
  CLICKUP_TOKEN: CLICKUP_FIELDS,
  CLICKUP_TEAM_ID: CLICKUP_FIELDS,
  CLICKUP_USER_ID: CLICKUP_FIELDS,
  GITHUB_TOKEN: GITHUB_FIELDS,
  GITHUB_USERNAME: GITHUB_FIELDS,
  SENTRY_TOKEN: SENTRY_FIELDS,
  SENTRY_PROJECTS: SENTRY_FIELDS,
};

export const CONFIG_TITLES = {
  ARGOCD_TOKEN: "Configure ArgoCD",
  ARGOCD_URL: "Configure ArgoCD",
  CLICKUP_TOKEN: "Configure ClickUp",
  CLICKUP_TEAM_ID: "Configure ClickUp",
  CLICKUP_USER_ID: "Configure ClickUp",
  GITHUB_TOKEN: "Configure GitHub",
  GITHUB_USERNAME: "Configure GitHub",
  SENTRY_TOKEN: "Configure Sentry",
  SENTRY_PROJECTS: "Configure Sentry",
};

export function configFieldsFor(key) {
  return CONFIG_GROUPS[key] ?? [];
}

export function configTitleFor(key) {
  return CONFIG_TITLES[key] ?? (key ? `Configure ${key}` : "Configure");
}
