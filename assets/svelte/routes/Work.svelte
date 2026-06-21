<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import DataWidget from '../components/DataWidget.svelte'
  import GithubMyPRs from '../widgets/GithubMyPRs.svelte'
  import { githubPRs, githubPendingReview } from '../lib/sources/github.js'
  import { clickupTasks } from '../lib/sources/clickup.js'

  const REPOS = ['innoshiftco/innosync', 'innoshiftco/innoup', 'innoshiftco/innowa']

  let myPrWidget
</script>

<DashboardLayout>
  <Col span={6}>
    <DataWidget
      title="pr by dev"
      collapsible
      display="table"
      source={githubPRs({ repos: REPOS })}
      config={{ sortable: true }}
    />

    <Widget title="my prs" collapsible onRefresh={() => myPrWidget?.refresh()}>
      <GithubMyPRs bind:this={myPrWidget} repos={REPOS} />
    </Widget>

    <DataWidget
      title="pending review"
      collapsible
      display="list"
      source={githubPendingReview({ repos: REPOS })}
    />
  </Col>

  <Col span={6}>
    <DataWidget
      title="task count"
      collapsible
      display="stat-group"
      source={clickupTasks({ mode: 'count' })}
    />

    <DataWidget
      title="my tasks"
      collapsible
      display="list"
      source={clickupTasks({ mode: 'list' })}
    />
  </Col>
</DashboardLayout>
