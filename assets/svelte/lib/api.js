const csrf = () => document.querySelector('meta[name="csrf-token"]')?.content ?? ''

async function request(method, path, body) {
  const init = {
    method,
    headers: { accept: 'application/json', 'x-csrf-token': csrf() },
  }
  if (body !== undefined) {
    init.headers['content-type'] = 'application/json'
    init.body = JSON.stringify(body)
  }
  const res = await fetch(path, init)
  const data = await res.json()
  if (!res.ok) throw new Error(data.error ?? `${res.status} ${res.statusText}`)
  return data
}

export const get = (path) => request('GET', path)
export const post = (path, body) => request('POST', path, body)
export const put = (path, body) => request('PUT', path, body)
export const del = (path) => request('DELETE', path)
