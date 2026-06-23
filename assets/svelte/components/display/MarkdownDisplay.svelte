<script>
  import { marked } from "marked";

  let { data, config = {} } = $props();
  let content = $derived(data?.content ?? "");

  marked.setOptions({ breaks: true, gfm: true });

  let html = $derived(content ? marked.parse(content) : "");
</script>

{#if !content}
  <div class="text-muted-foreground text-sm">no content</div>
{:else}
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="prose prose-sm max-w-none text-foreground
    [&_h1]:text-base [&_h1]:font-semibold [&_h1]:mb-2 [&_h1]:text-foreground
    [&_h2]:text-sm [&_h2]:font-semibold [&_h2]:mb-1.5 [&_h2]:text-foreground
    [&_h3]:text-sm [&_h3]:font-medium [&_h3]:mb-1 [&_h3]:text-muted-foreground
    [&_p]:text-sm [&_p]:mb-2 [&_p]:text-foreground [&_p:last-child]:mb-0
    [&_ul]:text-sm [&_ul]:space-y-1 [&_ul]:mb-2 [&_ul]:pl-4 [&_ul]:list-disc
    [&_ol]:text-sm [&_ol]:space-y-1 [&_ol]:mb-2 [&_ol]:pl-4 [&_ol]:list-decimal
    [&_li]:text-foreground
    [&_a]:text-primary [&_a]:underline [&_a:hover]:no-underline
    [&_code]:text-xs [&_code]:font-mono [&_code]:bg-secondary [&_code]:px-1 [&_code]:py-0.5 [&_code]:rounded-sm
    [&_pre]:bg-secondary [&_pre]:rounded-md [&_pre]:p-3 [&_pre]:overflow-x-auto [&_pre]:mb-2
    [&_pre_code]:bg-transparent [&_pre_code]:p-0
    [&_blockquote]:border-l-2 [&_blockquote]:border-border [&_blockquote]:pl-3 [&_blockquote]:text-muted-foreground [&_blockquote]:mb-2
    [&_hr]:border-border [&_hr]:mb-2
    [&_strong]:font-semibold [&_strong]:text-foreground
  "
  >
    {@html html}
  </div>
{/if}
