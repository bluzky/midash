<script>
  import { Tabs } from "bits-ui";
  import DashboardLayout from "../../components/DashboardLayout.svelte";
  import Col from "../../components/Col.svelte";
  import { navigate, router } from "../../lib/router.svelte.js";
  import { get, post, del } from "../../lib/api.js";
  import { Socket } from "phoenix";
  import { onMount } from "svelte";

  // Determine if we're showing a bin or the list
  let binId = $derived(
    router.path.startsWith("/toolkit/postbin/")
      ? router.path.replace("/toolkit/postbin/", "")
      : null,
  );

  // --- List mode ---
  let bins = $state([]);
  let loadingBins = $state(true);

  async function loadBins() {
    loadingBins = true;
    try {
      const res = await get("/api/postbin/bins");
      bins = res.data;
    } finally {
      loadingBins = false;
    }
  }

  async function createBin() {
    const res = await post("/api/postbin/bins", {});
    navigate(`/toolkit/postbin/${res.id}`);
  }

  async function deleteBin(id, e) {
    e.stopPropagation();
    e.preventDefault();
    await del(`/api/postbin/bins/${id}`);
    bins = bins.filter((b) => b.id !== id);
  }

  // --- Bin detail mode ---
  let requests = $state([]);
  let selectedReq = $state(null);
  let activeTab = $state("body");
  let loadingReqs = $state(true);
  let notFound = $state(false);
  let loadError = $state(null);

  async function loadBinRequests(id) {
    loadingReqs = true;
    notFound = false;
    loadError = null;
    try {
      const res = await get(`/api/postbin/bins/${id}/requests`);
      requests = res.data;
      selectedReq = requests[0] ?? null;
    } catch (e) {
      if (e.message?.includes("404") || e.message?.includes("not found"))
        notFound = true;
      else loadError = e.message;
    } finally {
      loadingReqs = false;
    }
  }

  // Phoenix Channel for real-time updates
  let socket, channel;

  function connectChannel(id) {
    socket = new Socket("/socket");
    socket.connect();
    channel = socket.channel(`bin:${id}`);
    channel.on("new_request", (req) => {
      requests = [req, ...requests];
      if (!selectedReq) selectedReq = req;
    });
    channel.join().receive("error", () => {});
  }

  function disconnectChannel() {
    channel?.leave();
    socket?.disconnect();
  }

  // Reactive: switch between list/bin modes
  $effect(() => {
    disconnectChannel();
    if (binId) {
      loadBinRequests(binId);
      connectChannel(binId);
    } else {
      loadBins();
    }
    return () => disconnectChannel();
  });

  function formatAge(iso) {
    const diff = Math.floor((Date.now() - new Date(iso)) / 1000);
    if (diff < 60) return `${diff}s ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    return `${Math.floor(diff / 3600)}h ago`;
  }

  function formatTime(iso) {
    return new Date(iso).toLocaleTimeString("en-US", { hour12: false });
  }

  function methodColor(m) {
    const map = {
      GET: "bg-primary/10 text-primary",
      POST: "bg-success/10 text-success",
      PUT: "bg-warning/10 text-warning",
      PATCH: "bg-warning/10 text-warning",
      DELETE: "bg-destructive/10 text-destructive",
    };
    return map[m] ?? "bg-muted text-muted-foreground";
  }

  function formatBody(body) {
    if (!body || body === "") return null;
    if (typeof body === "object") return JSON.stringify(body, null, 2);
    try {
      return JSON.stringify(JSON.parse(body), null, 2);
    } catch {
      return body;
    }
  }

  function copyUrl() {
    navigator.clipboard.writeText(`${window.location.origin}/bin/${binId}`);
  }

  const binUrl = $derived(
    binId ? `${window.location.origin}/bin/${binId}` : "",
  );
</script>

<DashboardLayout>
  <Col span={12}>
    {#if !binId}
      <!-- LIST PAGE -->
      <div class="mb-3 flex items-center gap-3">
        <button
          onclick={() => navigate("/toolkit")}
          class="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >Toolkit</button
        >
        <span class="text-sm text-muted-foreground">/</span>
        <span class="text-sm text-foreground">PostBin</span>
      </div>

      <div class="flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <p class="text-xs text-muted-foreground">
            create a bin, send HTTP requests to its URL, inspect them here
          </p>
          <button
            onclick={createBin}
            class="flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-foreground hover:bg-secondary transition-colors capitalize"
          >
            + new bin
          </button>
        </div>

        {#if loadingBins}
          <div class="text-muted-foreground text-sm">loading...</div>
        {:else if bins.length === 0}
          <div class="py-12 text-center text-xs text-muted-foreground">
            no bins yet — create one to start capturing requests
          </div>
        {:else}
          <div
            class="divide-y divide-border rounded-md border border-border overflow-hidden"
          >
            {#each bins as bin}
              <div
                class="group flex items-center gap-4 px-4 py-3 hover:bg-secondary/40 transition-colors"
              >
                <button
                  class="flex-1 flex items-center gap-4 min-w-0 text-left"
                  onclick={() => navigate(`/toolkit/postbin/${bin.id}`)}
                >
                  <span class="font-mono text-sm text-foreground">{bin.id}</span
                  >
                  <span class="text-xs text-muted-foreground font-mono truncate"
                    >{window.location.origin}/bin/{bin.id}</span
                  >
                  <span class="ml-auto text-xs text-muted-foreground shrink-0"
                    >{bin.count}
                    {bin.count === 1 ? "request" : "requests"}</span
                  >
                  <span class="text-xs text-muted-foreground shrink-0"
                    >{formatAge(bin.created_at)}</span
                  >
                </button>
                <button
                  onclick={(e) => deleteBin(bin.id, e)}
                  class="opacity-0 group-hover:opacity-100 p-1 rounded-lg text-muted-foreground hover:text-foreground transition-all"
                  title="delete bin"
                >
                  ✕
                </button>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    {:else if notFound}
      <!-- NOT FOUND -->
      <div class="py-12 text-center text-sm text-muted-foreground">
        bin not found — <button
          class="text-foreground hover:underline"
          onclick={() => navigate("/toolkit/postbin")}>go back</button
        >
      </div>
    {:else if loadError}
      <!-- LOAD ERROR -->
      <div class="py-12 text-center text-sm text-destructive">
        {loadError} —
        <button
          class="text-foreground hover:underline"
          onclick={() => navigate("/toolkit/postbin")}>go back</button
        >
      </div>
    {:else}
      <!-- BIN DETAIL PAGE -->
      <div class="mb-3 flex items-center gap-3">
        <button
          onclick={() => navigate("/toolkit/postbin")}
          class="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >PostBin</button
        >
        <span class="text-sm text-muted-foreground">/</span>
        <span class="text-sm text-foreground font-mono">{binId}</span>
        <div class="ml-auto flex items-center gap-2">
          <span class="text-xs text-muted-foreground font-mono">{binUrl}</span>
          <button
            onclick={copyUrl}
            class="text-xs text-muted-foreground hover:text-foreground transition-colors"
            title="copy URL">⎘</button
          >
        </div>
      </div>

      <div class="grid grid-cols-12 gap-4" style="height: calc(100vh - 10rem)">
        <!-- Request list -->
        <div
          class="col-span-4 flex flex-col rounded-lg border border-border bg-card overflow-hidden"
        >
          <div
            class="px-4 py-2.5 border-b border-border text-xs uppercase tracking-widest text-muted-foreground shrink-0"
          >
            requests ({requests.length})
          </div>
          {#if loadingReqs}
            <div
              class="flex-1 flex items-center justify-center text-xs text-muted-foreground"
            >
              loading...
            </div>
          {:else if requests.length === 0}
            <div
              class="flex-1 flex flex-col items-center justify-center text-xs text-muted-foreground gap-2"
            >
              <span class="text-2xl opacity-30">◎</span>
              waiting for requests…
            </div>
          {:else}
            <div class="flex-1 overflow-y-auto divide-y divide-border">
              {#each requests as req}
                <button
                  onclick={() => {
                    selectedReq = req;
                    activeTab = "body";
                  }}
                  class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-secondary/50 transition-colors {selectedReq?.id ===
                  req.id
                    ? 'bg-secondary'
                    : ''}"
                >
                  <span
                    class="text-xs font-bold px-1.5 py-0.5 rounded-full shrink-0 {methodColor(
                      req.method,
                    )}">{req.method}</span
                  >
                  <span
                    class="text-xs font-mono text-foreground truncate flex-1"
                    >{req.path}</span
                  >
                  <span class="text-xs text-muted-foreground shrink-0"
                    >{formatTime(req.inserted_at)}</span
                  >
                </button>
              {/each}
            </div>
          {/if}
        </div>

        <!-- Detail panel -->
        <div
          class="col-span-8 flex flex-col rounded-lg border border-border bg-card overflow-hidden"
        >
          <div
            class="px-4 py-2.5 border-b border-border text-xs uppercase tracking-widest text-muted-foreground shrink-0"
          >
            detail
          </div>
          {#if !selectedReq}
            <div
              class="flex-1 flex items-center justify-center text-xs text-muted-foreground"
            >
              select a request to inspect
            </div>
          {:else}
            <Tabs.Root
              bind:value={activeTab}
              class="flex-1 flex flex-col overflow-hidden"
            >
              <div
                class="flex items-center gap-3 px-4 py-3 border-b border-border shrink-0"
              >
                <span
                  class="text-xs font-bold px-2 py-1 rounded-full {methodColor(
                    selectedReq.method,
                  )}">{selectedReq.method}</span
                >
                <span class="text-sm font-mono text-foreground"
                  >{selectedReq.path}</span
                >
                <span class="ml-auto text-xs text-muted-foreground"
                  >{formatTime(selectedReq.inserted_at)}</span
                >
              </div>

              <Tabs.List
                class="flex gap-1 border-b border-border px-4 shrink-0"
              >
                <Tabs.Trigger
                  value="body"
                  class="px-3 py-2 text-xs border-b-2 -mb-px transition-colors outline-none
                    data-[state=active]:border-primary data-[state=active]:text-primary
                    data-[state=inactive]:border-transparent data-[state=inactive]:text-muted-foreground hover:text-foreground"
                >
                  body
                </Tabs.Trigger>
                <Tabs.Trigger
                  value="headers"
                  class="px-3 py-2 text-xs border-b-2 -mb-px transition-colors outline-none
                    data-[state=active]:border-primary data-[state=active]:text-primary
                    data-[state=inactive]:border-transparent data-[state=inactive]:text-muted-foreground hover:text-foreground"
                >
                  headers <span class="ml-1 text-xs opacity-60"
                    >({Object.keys(selectedReq.headers ?? {}).length})</span
                  >
                </Tabs.Trigger>
                <Tabs.Trigger
                  value="query"
                  class="px-3 py-2 text-xs border-b-2 -mb-px transition-colors outline-none
                    data-[state=active]:border-primary data-[state=active]:text-primary
                    data-[state=inactive]:border-transparent data-[state=inactive]:text-muted-foreground hover:text-foreground"
                >
                  query <span class="ml-1 text-xs opacity-60"
                    >({Object.keys(selectedReq.query ?? {}).length})</span
                  >
                </Tabs.Trigger>
              </Tabs.List>

              <div class="flex-1 overflow-y-auto p-4">
                <Tabs.Content value="body">
                  {@const body = formatBody(selectedReq.body)}
                  {#if !body}
                    <div class="text-xs text-muted-foreground">empty body</div>
                  {:else}
                    <div class="mb-2 text-xs text-muted-foreground font-mono">
                      content-type: {selectedReq.content_type}
                    </div>
                    <pre
                      class="rounded-md border border-border bg-card p-4 text-xs font-mono text-foreground overflow-x-auto whitespace-pre-wrap break-all">{body}</pre>
                  {/if}
                </Tabs.Content>
                <Tabs.Content value="headers">
                  {@const headers = Object.entries(
                    selectedReq.headers ?? {},
                  ).sort()}
                  {#if headers.length === 0}
                    <div class="text-xs text-muted-foreground">no headers</div>
                  {:else}
                    <div
                      class="divide-y divide-border rounded-lg border border-border overflow-hidden"
                    >
                      {#each headers as [k, v]}
                        <div class="flex px-3 py-2 text-xs font-mono gap-4">
                          <span
                            class="text-muted-foreground w-56 shrink-0 truncate"
                            >{k}</span
                          >
                          <span class="text-foreground break-all">{v}</span>
                        </div>
                      {/each}
                    </div>
                  {/if}
                </Tabs.Content>
                <Tabs.Content value="query">
                  {@const query = Object.entries(
                    selectedReq.query ?? {},
                  ).sort()}
                  {#if query.length === 0}
                    <div class="text-xs text-muted-foreground">
                      no query params
                    </div>
                  {:else}
                    <div
                      class="divide-y divide-border rounded-lg border border-border overflow-hidden"
                    >
                      {#each query as [k, v]}
                        <div class="flex px-3 py-2 text-xs font-mono gap-4">
                          <span
                            class="text-muted-foreground w-56 shrink-0 truncate"
                            >{k}</span
                          >
                          <span class="text-foreground break-all">{v}</span>
                        </div>
                      {/each}
                    </div>
                  {/if}
                </Tabs.Content>
              </div>
            </Tabs.Root>
          {/if}
        </div>
      </div>
    {/if}
  </Col>
</DashboardLayout>
