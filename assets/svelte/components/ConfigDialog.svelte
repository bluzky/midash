<script>
  import { X } from "@lucide/svelte";
  import { post } from "../lib/api.js";

  let {
    open = $bindable(false),
    title = "Configure",
    fields = [],
    onSaved = null,
  } = $props();

  let values = $state({});
  let saving = $state(false);
  let error = $state(null);
  let initializedForOpen = false;

  $effect(() => {
    if (!open) {
      initializedForOpen = false;
      return;
    }
    if (initializedForOpen) return;

    values = Object.fromEntries(fields.map((field) => [field.key, ""]));
    error = null;
    initializedForOpen = true;
  });

  function close() {
    if (saving) return;
    open = false;
  }

  function handleKeydown(e) {
    if (open && e.key === "Escape") close();
  }

  async function save() {
    saving = true;
    error = null;
    try {
      await post("/api/config", values);
      open = false;
      await onSaved?.();
    } catch (e) {
      error = e.message;
    } finally {
      saving = false;
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

{#if open}
  <div
    role="presentation"
    class="fixed inset-0 z-[100] flex items-center justify-center bg-background/80 backdrop-blur-sm p-4"
    onclick={close}
  >
    <div
      role="presentation"
      class="w-full max-w-lg rounded-lg border border-border bg-card shadow-xl"
      onclick={(e) => e.stopPropagation()}
    >
      <div
        class="flex items-center justify-between border-b border-border px-4 py-3"
      >
        <h2
          class="text-sm font-medium uppercase tracking-widest text-foreground"
        >
          {title}
        </h2>
        <button
          onclick={close}
          class="rounded-md p-1 text-muted-foreground hover:bg-secondary hover:text-foreground transition-colors"
          title="close"
        >
          <X class="h-4 w-4" />
        </button>
      </div>

      <div class="space-y-4 p-4">
        {#each fields as field}
          <label class="flex flex-col gap-1">
            <span
              class="text-xs uppercase tracking-widest text-muted-foreground"
              >{field.label ?? field.key}</span
            >
            {#if field.multiline}
              <textarea
                bind:value={values[field.key]}
                placeholder={field.placeholder ?? ""}
                rows={field.rows ?? 4}
                class="rounded-md border border-border bg-background px-3 py-2 font-mono text-sm text-foreground outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
              ></textarea>
            {:else}
              <input
                bind:value={values[field.key]}
                type={field.secret ? "password" : "text"}
                placeholder={field.placeholder ?? ""}
                class="rounded-md border border-border bg-background px-3 py-2 font-mono text-sm text-foreground outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
              />
            {/if}
            {#if field.help}
              <span class="text-xs text-muted-foreground">{field.help}</span>
            {/if}
          </label>
        {/each}

        {#if error}
          <div
            class="rounded-md border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-destructive"
          >
            {error}
          </div>
        {/if}
      </div>

      <div class="flex justify-end gap-2 border-t border-border px-4 py-3">
        <button
          onclick={close}
          class="rounded-md px-3 py-1.5 text-sm text-muted-foreground hover:bg-secondary hover:text-foreground transition-colors"
          >cancel</button
        >
        <button
          onclick={save}
          disabled={saving}
          class="rounded-md bg-primary px-3 py-1.5 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 transition-colors"
          >{saving ? "saving..." : "save"}</button
        >
      </div>
    </div>
  </div>
{/if}
