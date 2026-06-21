<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import GithubPRs from '../widgets/GithubPRs.svelte'
  import GithubMyPRs from '../widgets/GithubMyPRs.svelte'
  import GithubPendingReview from '../widgets/GithubPendingReview.svelte'
  import ClickupTasks from '../widgets/ClickupTasks.svelte'

  const REPOS = ['innoshiftco/innosync', 'innoshiftco/innoup', 'innoshiftco/innowa']

  let prWidget, myPrWidget, pendingWidget, countWidget, listWidget
</script>

<DashboardLayout>
  <Col span={6}>
    <Widget title="pr by dev" collapsible onRefresh={() => prWidget?.refresh()}>
      <GithubPRs bind:this={prWidget} repos={REPOS} />
    </Widget>

    <Widget title="my prs" collapsible onRefresh={() => myPrWidget?.refresh()}>
      <GithubMyPRs bind:this={myPrWidget} repos={REPOS} />
    </Widget>

    <Widget title="pending review" collapsible onRefresh={() => pendingWidget?.refresh()}>
      <GithubPendingReview bind:this={pendingWidget} repos={REPOS} />
    </Widget>
  </Col>

  <Col span={6}>
    <Widget title="task count" collapsible onRefresh={() => countWidget?.refresh()}>
      <ClickupTasks bind:this={countWidget} mode="count" />
    </Widget>

    <Widget title="my tasks" collapsible onRefresh={() => listWidget?.refresh()}>
      <ClickupTasks bind:this={listWidget} mode="list" />
    </Widget>
  </Col>
</DashboardLayout>
