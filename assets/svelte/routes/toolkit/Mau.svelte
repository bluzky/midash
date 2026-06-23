<script>
  import DashboardLayout from "../../components/DashboardLayout.svelte";
  import Col from "../../components/Col.svelte";
  import { navigate } from "../../lib/router.svelte.js";
  import { post } from "../../lib/api.js";
  import { onMount } from "svelte";

  const DEFAULT_TPL =
    "Hello, {{ name }}!\n\n{% if items %}\nItems:\n{% for item in items %}\n- {{ item | upper_case }}\n{% endfor %}\n{% endif %}";
  const DEFAULT_PARAMS =
    '{\n  "name": "World",\n  "items": ["apple", "banana", "cherry"]\n}';

  let output = $state(null);
  let error = $state(null);
  let loading = $state(false);

  let tplEditorEl, tplLineNumEl;
  let paramsEditorEl, paramsLineNumEl;

  function makeLineUpdater(lineNumEl) {
    return (text) => {
      const count = text.split("\n").length;
      lineNumEl.innerHTML = Array.from(
        { length: count },
        (_, i) => `<div>${i + 1}</div>`,
      ).join("");
    };
  }

  onMount(async () => {
    const { CodeJar } = await import("codejar");
    const Prism = (await import("prismjs")).default;
    await Promise.all([
      import("prismjs/components/prism-markup.js"),
      import("prismjs/components/prism-markup-templating.js"),
      import("prismjs/components/prism-json.js"),
    ]);
    await import("prismjs/components/prism-liquid.js");

    const updateTplLines = makeLineUpdater(tplLineNumEl);
    const tplJar = CodeJar(
      tplEditorEl,
      (el) => {
        el.innerHTML = Prism.highlight(
          el.textContent,
          Prism.languages.liquid,
          "liquid",
        );
        updateTplLines(el.textContent);
      },
      { tab: "  " },
    );
    tplJar.updateCode(DEFAULT_TPL);
    tplEditorEl._jar = tplJar;

    const updateParamsLines = makeLineUpdater(paramsLineNumEl);
    const paramsJar = CodeJar(
      paramsEditorEl,
      (el) => {
        el.innerHTML = Prism.highlight(
          el.textContent,
          Prism.languages.json,
          "json",
        );
        updateParamsLines(el.textContent);
      },
      { tab: "  " },
    );
    paramsJar.updateCode(DEFAULT_PARAMS);
    paramsEditorEl._jar = paramsJar;
  });

  async function render() {
    const template = tplEditorEl?._jar?.toString() ?? "";
    const params = paramsEditorEl?._jar?.toString() ?? "";
    loading = true;
    output = null;
    error = null;
    try {
      const res = await post("/api/toolkit/mau", { template, params });
      if (res.error) error = res.error;
      else output = res.output;
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
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
      <span class="text-sm text-foreground">Mau Template</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >Template</span
          >
          <div
            class="flex h-72 w-full rounded-md border border-border bg-card font-mono text-sm text-foreground overflow-auto focus-within:border-primary focus-within:ring-1 focus-within:ring-primary/20"
          >
            <div
              bind:this={tplLineNumEl}
              aria-hidden="true"
              class="select-none text-right text-muted-foreground py-3 px-2 leading-6 border-r border-border min-w-[2.5rem] shrink-0 [&>div]:leading-6"
            ></div>
            <div
              bind:this={tplEditorEl}
              contenteditable="true"
              spellcheck="false"
              class="flex-1 p-3 leading-6 outline-none"
            ></div>
          </div>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >Params <span class="normal-case">(JSON)</span></span
          >
          <div
            class="flex h-72 w-full rounded-md border border-border bg-card font-mono text-sm text-foreground overflow-auto focus-within:border-primary focus-within:ring-1 focus-within:ring-primary/20"
          >
            <div
              bind:this={paramsLineNumEl}
              aria-hidden="true"
              class="select-none text-right text-muted-foreground py-3 px-2 leading-6 border-r border-border min-w-[2.5rem] shrink-0 [&>div]:leading-6"
            ></div>
            <div
              bind:this={paramsEditorEl}
              contenteditable="true"
              spellcheck="false"
              class="flex-1 p-3 leading-6 outline-none"
            ></div>
          </div>
        </div>
      </div>

      <button
        onclick={render}
        disabled={loading}
        class="btn-primary self-start px-4 py-2 capitalize"
      >
        {loading ? "rendering..." : "render"}
      </button>

      {#if output !== null || error !== null}
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >Output</span
          >
          <pre
            class="rounded-md border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap {error
              ? 'bg-destructive/10 text-destructive'
              : 'bg-secondary text-success'}">{error ?? output}</pre>
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
