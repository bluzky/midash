<script>
  import DashboardLayout from "../components/DashboardLayout.svelte";
  import Col from "../components/Col.svelte";
  import DataWidget from "../components/DataWidget.svelte";
  import {
    githubPRs,
    githubMyPRs,
    githubPendingReview,
  } from "../lib/sources/github.js";
  import { clickupTasks } from "../lib/sources/clickup.js";

  const REPOS = [
    "innoshiftco/innosync",
    "innoshiftco/innoup",
    "innoshiftco/innowa",
  ];
</script>

<DashboardLayout>
  <Col span={6}>
    <DataWidget
      title="pr by dev"
      collapsible
      display="table"
      source={githubPRs({ repos: REPOS })}
      config={{ sortable: true }}
      configGroup="GITHUB_TOKEN"
    />

    <DataWidget
      title="my prs"
      collapsible
      display="tabs-list"
      source={githubMyPRs({ repos: REPOS })}
      configGroup="GITHUB_TOKEN"
    />

    <DataWidget
      title="pending review"
      collapsible
      display="tabs-list"
      source={githubPendingReview({ repos: REPOS })}
      configGroup="GITHUB_TOKEN"
    />
  </Col>

  <Col span={6}>
    <DataWidget
      title="task count"
      collapsible
      display="stat-group"
      source={clickupTasks({ mode: "count" })}
      configGroup="CLICKUP_TOKEN"
    />

    <DataWidget
      title="my tasks"
      collapsible
      display="tabs-list"
      source={clickupTasks({ mode: "tabs" })}
      configGroup="CLICKUP_TOKEN"
    />
  </Col>
</DashboardLayout>
