<script>
  import DashboardLayout from "../components/DashboardLayout.svelte";
  import Col from "../components/Col.svelte";
  import Widget from "../components/Widget.svelte";
  import Spinner from "../components/Spinner.svelte";
  import ConfigDialog from "../components/ConfigDialog.svelte";
  import { Settings2 } from "@lucide/svelte";
  import { createQuery } from "@tanstack/svelte-query";
  import { get } from "../lib/api.js";
  import { configFieldsFor, configTitleFor } from "../lib/config-schema.js";

  const CONFIG_KEY = "ARGOCD_URL";

  const q = createQuery(() => ({
    queryKey: ["/api/argocd/apps"],
    queryFn: () => get("/api/argocd/apps").then((r) => r.data),
    staleTime: 30_000,
    refetchInterval: 60_000,
  }));

  let configOpen = $state(false);

  let grouped = $derived({
    prod: (q.data ?? []).filter((a) => a.name?.toLowerCase().includes("prod")),
    stg: (q.data ?? []).filter((a) => a.name?.toLowerCase().includes("stg")),
    other: (q.data ?? []).filter(
      (a) =>
        !a.name?.toLowerCase().includes("prod") &&
        !a.name?.toLowerCase().includes("stg"),
    ),
  });

  function healthColor(s) {
    if (s === "Healthy") return "text-green-400";
    if (s === "Degraded") return "text-red-400";
    if (s === "Progressing") return "text-yellow-400";
    return "text-muted-foreground";
  }

  function syncColor(s) {
    if (s === "Synced") return "text-green-400";
    if (s === "OutOfSync") return "text-yellow-400";
    return "text-muted-foreground";
  }
</script>

{#snippet appList(list)}
  {#if list.length === 0}
    <div class="text-muted-foreground text-sm px-1">no apps</div>
  {:else}
    {#each list as app}
      <Widget title={app.name} collapsible>
        <div class="flex items-center gap-2 mb-2 text-xs text-muted-foreground">
          <span
            >app: <span class={healthColor(app.health_status)}
              >{app.health_status}</span
            ></span
          >
          <span>·</span>
          <span
            >sync: <span class={syncColor(app.sync_status)}
              >{app.sync_status}</span
            ></span
          >
        </div>
        {#each app.resources ?? [] as r}
          <div
            class="flex items-center justify-between py-1 text-sm font-mono border-t border-border"
          >
            <span class="truncate text-foreground">{r.name}</span>
            <span class="{healthColor(r.health_status)} shrink-0 ml-2 text-xs"
              >● {r.health_status}</span
            >
          </div>
        {/each}
      </Widget>
    {/each}
  {/if}
{/snippet}

<DashboardLayout>
  {#if q.isPending}
    <Col span={12}>
      <Spinner />
    </Col>
  {:else if q.isError}
    <Col span={12}>
      <Widget title="argocd">
        <div
          class="flex flex-col items-center justify-center gap-3 py-4 text-center"
        >
          <div class="text-destructive text-sm">{q.error.message}</div>
          <button
            onclick={() => (configOpen = true)}
            class="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm text-foreground hover:bg-secondary transition-colors"
          >
            <Settings2 class="h-3.5 w-3.5" />
            <span>configure</span>
          </button>
        </div>
      </Widget>
    </Col>
  {:else}
    <Col span={4}>
      <div class="text-xs text-destructive uppercase tracking-widest mb-3 px-1">
        production
      </div>
      {@render appList(grouped.prod)}
    </Col>

    <Col span={4}>
      <div class="text-xs text-yellow-400 uppercase tracking-widest mb-3 px-1">
        staging
      </div>
      {@render appList(grouped.stg)}
    </Col>

    <Col span={4}>
      <div
        class="text-xs text-muted-foreground uppercase tracking-widest mb-3 px-1"
      >
        dev / other
      </div>
      {@render appList(grouped.other)}
    </Col>
  {/if}
</DashboardLayout>

<ConfigDialog
  bind:open={configOpen}
  title={configTitleFor(CONFIG_KEY)}
  fields={configFieldsFor(CONFIG_KEY)}
  onSaved={q.refetch}
/>
