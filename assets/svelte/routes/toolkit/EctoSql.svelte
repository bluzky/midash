<script>
  import DashboardLayout from "../../components/DashboardLayout.svelte";
  import Col from "../../components/Col.svelte";
  import { navigate } from "../../lib/router.svelte.js";

  const DEFAULT =
    'SELECT m0."id", m0."sku", m0."name" FROM "htf3"."master_products" AS m0 WHERE (m0."sku" = $1) ["S4-4800119218473"]';

  let input = $state(DEFAULT);
  let output = $state(null);
  let error = $state(null);
  let copied = $state(false);

  function splitLog(log) {
    const trimmed = log.trim();
    if (!trimmed.endsWith("}") && !trimmed.endsWith("]")) {
      throw new Error('Log must end with Ecto params list, e.g. ["sku"]');
    }

    let depth = 0;
    let inString = false;
    let escape = false;

    for (let i = trimmed.length - 1; i >= 0; i--) {
      const ch = trimmed[i];

      if (inString) {
        if (escape) {
          escape = false;
        } else if (ch === "\\") {
          escape = true;
        } else if (ch === '"') {
          inString = false;
        }
        continue;
      }

      if (ch === '"') {
        inString = true;
      } else if (ch === "]" || ch === "}") {
        depth++;
      } else if (ch === "[" || ch === "{") {
        depth--;
        if (depth === 0 && ch === "[") {
          return {
            sql: trimmed.slice(0, i).trim(),
            paramsText: trimmed.slice(i),
          };
        }
      }
    }

    throw new Error("Could not find params list");
  }

  function toSqlScalar(value) {
    if (value === null) return "NULL";
    if (typeof value === "number")
      return Number.isFinite(value) ? String(value) : "NULL";
    if (typeof value === "boolean") return value ? "TRUE" : "FALSE";
    if (value instanceof Date)
      return `'${value.toISOString().replaceAll("'", "''")}'`;
    if (typeof value === "object") {
      return `'${JSON.stringify(value).replaceAll("'", "''")}'`;
    }

    return `'${String(value).replaceAll("'", "''")}'`;
  }

  function toSqlArray(value) {
    if (!Array.isArray(value)) return toSqlLiteral(value);
    return `ARRAY[${value.map(toSqlScalar).join(", ")}]`;
  }

  function toSqlLiteral(value) {
    if (Array.isArray(value)) {
      if (value.length === 0) return "(NULL)";
      return `(${value.map(toSqlScalar).join(", ")})`;
    }

    return toSqlScalar(value);
  }

  function convert() {
    output = null;
    error = null;

    try {
      const { sql, paramsText } = splitLog(input);
      const params = JSON.parse(paramsText);

      if (!Array.isArray(params)) {
        throw new Error("Params must be JSON array");
      }

      output = sql
        .replace(/ANY\(\$(\d+)\)/gi, (match, indexText) => {
          const index = Number(indexText) - 1;
          if (index < 0 || index >= params.length) return match;
          return `ANY(${toSqlArray(params[index])})`;
        })
        .replace(/\$(\d+)/g, (match, indexText) => {
          const index = Number(indexText) - 1;
          if (index < 0 || index >= params.length) return match;
          return toSqlLiteral(params[index]);
        });
    } catch (e) {
      error = e.message;
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
      <span class="text-sm text-foreground">Ecto Log → SQL</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label
            for="ecto-log-input"
            class="text-xs text-muted-foreground uppercase tracking-widest"
            >Ecto debug log</label
          >
          <textarea
            id="ecto-log-input"
            bind:value={input}
            rows="18"
            spellcheck="false"
            class="h-96 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
          ></textarea>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest"
            >SQL</span
          >
          <pre
            class="h-96 rounded-lg border border-border p-3 text-sm font-mono overflow-auto whitespace-pre-wrap {error
              ? 'bg-destructive/10 text-destructive'
              : 'bg-secondary text-foreground'}">{error ??
              output ??
              "-- converted SQL appears here"}</pre>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <button onclick={convert} class="btn-primary px-4 py-2">Convert</button>
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
