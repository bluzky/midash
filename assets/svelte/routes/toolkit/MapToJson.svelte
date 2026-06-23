<script>
  import DashboardLayout from "../../components/DashboardLayout.svelte";
  import Col from "../../components/Col.svelte";
  import { navigate } from "../../lib/router.svelte.js";
  import { post } from "../../lib/api.js";
  import { onMount } from "svelte";

  const DEFAULT =
    '%{\n  name: "Alice",\n  age: 30,\n  tags: ["elixir", "phoenix"],\n  meta: %{active: true}\n}';

  let output = $state(null);
  let error = $state(null);
  let loading = $state(false);
  let copied = $state(false);

  let editorEl, lineNumEl;

  onMount(async () => {
    const { CodeJar } = await import("codejar");
    const Prism = (await import("prismjs")).default;
    await import("prismjs/components/prism-elixir.js");

    const updateLines = (text) => {
      const count = text.split("\n").length;
      lineNumEl.innerHTML = Array.from(
        { length: count },
        (_, i) => `<div>${i + 1}</div>`,
      ).join("");
    };

    const jar = CodeJar(
      editorEl,
      (el) => {
        el.innerHTML = Prism.highlight(
          el.textContent,
          Prism.languages.elixir,
          "elixir",
        );
        updateLines(el.textContent);
      },
      { tab: "  " },
    );
    jar.updateCode(DEFAULT);
    editorEl._jar = jar;
  });

  async function convert(direction) {
    const input = editorEl?._jar?.toString() ?? "";
    loading = true;
    output = null;
    error = null;
    try {
      const endpoint =
        direction === "map-to-json"
          ? "/api/toolkit/map-to-json"
          : "/api/toolkit/json-to-map";
      const res = await post(endpoint, { input });
      if (res.error) error = res.error;
      else output = res.output;
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  async function copy() {
    if (!output) return;
    await navigator.clipboard.writeText(output);
    copied = true;
    setTimeout(() => (copied = false), 1500);
  }
</script>

<DashboardLayout>
  <Col span={12}>
    <div class="mb-3 flex items-center gap-3">
      <button
        onclick={() => navigate("/toolkit")}
        class="text-sm text-muted-foreground hover:text-foreground transition-colors"
        >Toolkit</button
      >
      <span class="text-sm text-muted-foreground">/</span>
      <span class="text-sm text-foreground">Map ↔ JSON</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >Input</span
          >
          <div
            class="flex h-96 w-full rounded-md border border-border bg-card font-mono text-sm text-foreground overflow-auto focus-within:border-primary focus-within:ring-1 focus-within:ring-primary/20"
          >
            <div
              bind:this={lineNumEl}
              aria-hidden="true"
              class="select-none text-right text-muted-foreground py-3 px-2 leading-6 border-r border-border min-w-[2.5rem] shrink-0 [&>div]:leading-6"
            ></div>
            <div
              bind:this={editorEl}
              contenteditable="true"
              spellcheck="false"
              class="flex-1 p-3 leading-6 outline-none"
            ></div>
          </div>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >Output</span
          >
          <pre
            class="h-96 rounded-lg border border-border p-3 text-sm font-mono overflow-auto whitespace-pre-wrap {error
              ? 'bg-destructive/10 text-destructive'
              : 'bg-secondary text-foreground'}">{error ??
              output ??
              "// output appears here"}</pre>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <div class="flex gap-2">
          <button
            onclick={() => convert("map-to-json")}
            disabled={loading}
            class="btn-primary px-4 py-2"
          >
            Map → JSON
          </button>
          <button
            onclick={() => convert("json-to-map")}
            disabled={loading}
            class="px-4 py-2 rounded-md border border-border text-foreground font-medium hover:bg-secondary transition-colors"
          >
            JSON → Map
          </button>
        </div>
        <button
          onclick={copy}
          disabled={!output}
          class="px-4 py-2 rounded-md border border-border text-foreground font-medium hover:bg-secondary transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>
    </div>
  </Col>
</DashboardLayout>
