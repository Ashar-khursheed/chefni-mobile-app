import { useState } from 'react';
import { useRouter } from 'next/router';
import { api, setToken, ApiError } from '../lib/api';

export default function Login() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const json = await api.post('/auth/login', { email, password });
      if (!json.user || json.user.role !== 'admin') {
        setToken(null);
        setError('This account is not an administrator.');
        return;
      }
      setToken(json.access_token);
      router.push('/');
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: '#321925',
        color: '#FFF5EA',
        fontFamily: 'system-ui, -apple-system, sans-serif',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <form
        onSubmit={handleSubmit}
        style={{
          background: '#26121B',
          border: '1px solid #572C3E',
          borderRadius: '16px',
          padding: '32px',
          width: '340px',
          display: 'flex',
          flexDirection: 'column',
          gap: '14px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
          <div
            style={{
              width: '36px',
              height: '36px',
              borderRadius: '50%',
              backgroundColor: '#D83A75',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold',
            }}
          >
            C
          </div>
          <div>
            <h1 style={{ fontSize: '18px', margin: 0, color: '#D83A75' }}>Chefni AI</h1>
            <span style={{ fontSize: '11px', color: '#38BDF8' }}>Admin sign in</span>
          </div>
        </div>

        <label style={{ fontSize: '12px', color: '#D8C7B5' }}>
          Email
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={inputStyle}
          />
        </label>
        <label style={{ fontSize: '12px', color: '#D8C7B5' }}>
          Password
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={inputStyle}
          />
        </label>

        {error && (
          <div style={{ color: '#F87171', fontSize: '12.5px' }}>{error}</div>
        )}

        <button
          type="submit"
          disabled={loading}
          style={{
            marginTop: '8px',
            padding: '12px',
            borderRadius: '10px',
            border: 'none',
            backgroundColor: '#D83A75',
            color: '#fff',
            fontWeight: 'bold',
            cursor: loading ? 'default' : 'pointer',
            opacity: loading ? 0.7 : 1,
          }}
        >
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}

const inputStyle = {
  display: 'block',
  width: '100%',
  marginTop: '5px',
  padding: '10px 12px',
  borderRadius: '8px',
  border: '1px solid #572C3E',
  background: '#321925',
  color: '#FFF5EA',
  fontSize: '14px',
  boxSizing: 'border-box',
};
