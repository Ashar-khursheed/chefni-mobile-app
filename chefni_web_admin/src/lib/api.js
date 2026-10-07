// Thin client for the Chefni Laravel API. Mirrors the mobile app's
// ApiClient: bearer token in localStorage, {success, message, errors} JSON
// envelope, no silent fallback to fake data on failure.

const API_BASE =
  process.env.NEXT_PUBLIC_CHEFNI_API_URL || 'http://127.0.0.1:8000/api';

const TOKEN_KEY = 'chefni_admin_token';

export function getToken() {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (typeof window === 'undefined') return;
  if (token) {
    window.localStorage.setItem(TOKEN_KEY, token);
  } else {
    window.localStorage.removeItem(TOKEN_KEY);
  }
}

export class ApiError extends Error {
  constructor(message, status, errors) {
    super(message);
    this.status = status;
    this.errors = errors;
  }
}

async function request(method, path, body) {
  const headers = { Accept: 'application/json' };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  let response;
  try {
    response = await fetch(`${API_BASE}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(
      `Cannot reach the Chefni server at ${API_BASE}. Check your connection and that the API is running.`,
      null,
    );
  }

  let json;
  try {
    json = await response.json();
  } catch {
    throw new ApiError(`Unexpected response (HTTP ${response.status}).`, response.status);
  }

  if (!response.ok) {
    throw new ApiError(json.message || `Request failed (HTTP ${response.status}).`, response.status, json.errors);
  }

  return json;
}

export const api = {
  get: (path) => request('GET', path),
  post: (path, body) => request('POST', path, body),
  patch: (path, body) => request('PATCH', path, body),
};

export { API_BASE };
