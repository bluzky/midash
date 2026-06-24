<script>
  import QRCode from "qrcode";
  import DashboardLayout from "../../components/DashboardLayout.svelte";
  import Col from "../../components/Col.svelte";
  import { navigate } from "../../lib/router.svelte.js";
  import { post } from "../../lib/api.js";

  let input = $state("");
  let codes = $state([]);
  let loadingMode = $state(null);
  let mode = $state("barcode");

  async function generate(type) {
    const values = input
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean);
    if (!values.length) return;
    loadingMode = type;
    mode = type;
    try {
      if (type === "qr") {
        codes = await Promise.all(
          values.map(async (value) => ({
            value,
            svg: await QRCode.toString(value, {
              type: "svg",
              margin: 1,
              width: 180,
            }),
            error: null,
          })),
        );
      } else {
        const res = await post("/api/toolkit/barcode", { codes: values });
        codes = res.data;
      }
    } catch (e) {
      codes = values.map((value) => ({ value, svg: null, error: e.message }));
    } finally {
      loadingMode = null;
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
      <span class="text-sm text-foreground">Barcode Generator</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-2">
        <label
          for="barcode-input"
          class="text-xs text-muted-foreground uppercase tracking-widest"
          >Codes (one per line)</label
        >
        <textarea
          id="barcode-input"
          bind:value={input}
          rows="6"
          placeholder="ABC-001&#10;ABC-002&#10;ABC-003"
          class="w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-y focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
        ></textarea>
        <div class="flex items-center gap-3">
          <button
            onclick={() => generate("barcode")}
            disabled={loadingMode !== null}
            class="btn-primary px-4 py-2 capitalize"
          >
            {loadingMode === "barcode" ? "generating..." : "generate barcode"}
          </button>
          <button
            onclick={() => generate("qr")}
            disabled={loadingMode !== null}
            class="btn-primary px-4 py-2 capitalize"
          >
            {loadingMode === "qr" ? "generating..." : "generate qr code"}
          </button>
          {#if codes.length}
            <button
              onclick={() => window.print()}
              class="ml-auto px-4 py-2 rounded-md border border-border text-foreground font-medium hover:bg-secondary transition-colors capitalize"
            >
              print
            </button>
          {/if}
        </div>
      </div>

      {#if codes.length}
        <div class="grid grid-cols-2 gap-4 print:gap-2" id="barcode-grid">
          {#each codes as b}
            <div
              class="flex flex-col items-center justify-center gap-1 rounded-lg border border-border bg-card p-4"
            >
              {#if b.error}
                <div class="text-xs text-destructive font-mono">
                  {b.value}: {b.error}
                </div>
              {:else}
                <div
                  class={mode === "qr"
                    ? "[&_svg]:size-40 [&_svg]:max-w-full [&_svg]:h-auto"
                    : "[&_svg]:max-w-full [&_svg]:h-auto"}
                >
                  {@html b.svg}
                </div>
                <span class="text-xs font-mono text-foreground">{b.value}</span>
              {/if}
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
