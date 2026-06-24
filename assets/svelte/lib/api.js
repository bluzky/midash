const csrf = () =>
  document.querySelector('meta[name="csrf-token"]')?.content ?? "";

async function request(method, path, body) {
  const init = {
    method,
    headers: { accept: "application/json", "x-csrf-token": csrf() },
  };
  if (body !== undefined) {
    init.headers["content-type"] = "application/json";
    init.body = JSON.stringify(body);
  }
  const res = await fetch(path, init);
  const data = await res.json();
  if (!res.ok) throw new Error(data.error ?? `${res.status} ${res.statusText}`);
  return data;
}

// Deduplicate concurrent GET requests to the same URL.
const getInflight = new Map();

export function get(path) {
  if (getInflight.has(path)) return getInflight.get(path);
  const p = request("GET", path).finally(() => getInflight.delete(path));
  getInflight.set(path, p);
  return p;
}

export const post = (path, body) => request("POST", path, body);
export const put = (path, body) => request("PUT", path, body);
export const del = (path) => request("DELETE", path);
