<script>
  import { router } from "./lib/router.svelte.js";
  import Work from "./routes/Work.svelte";
  import Crypto from "./routes/Crypto.svelte";
  import Monitor from "./routes/Monitor.svelte";
  import ArgoCDPage from "./routes/ArgoCD.svelte";
  import Toolkit from "./routes/Toolkit.svelte";
  import ElixirExecute from "./routes/toolkit/ElixirExecute.svelte";
  import Barcode from "./routes/toolkit/Barcode.svelte";
  import PostBin from "./routes/toolkit/PostBin.svelte";
  import Mau from "./routes/toolkit/Mau.svelte";
  import MapToJson from "./routes/toolkit/MapToJson.svelte";
</script>

{#if router.path === "/" || router.path === "/work"}
  <Work />
{:else if router.path === "/crypto"}
  <Crypto />
{:else if router.path === "/monitor"}
  <Monitor />
{:else if router.path === "/argocd"}
  <ArgoCDPage />
{:else if router.path === "/toolkit"}
  <Toolkit />
{:else if router.path === "/toolkit/elixir-execute"}
  <ElixirExecute />
{:else if router.path === "/toolkit/barcode"}
  <Barcode />
{:else if router.path.startsWith("/toolkit/postbin")}
  <PostBin />
{:else if router.path === "/toolkit/mau"}
  <Mau />
{:else if router.path === "/toolkit/map-to-json"}
  <MapToJson />
{:else}
  <Work />
{/if}
