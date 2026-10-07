import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { api, getToken, setToken, ApiError } from '../lib/api';

const COLORS = {
  bg: '#321925',
  panel: '#26121B',
  border: '#572C3E',
  text: '#FFF5EA',
  muted: '#D8C7B5',
  pink: '#D83A75',
  blue: '#38BDF8',
  green: '#4ADE80',
};

export default function WebAdminDashboard() {
  const router = useRouter();
  const [authChecked, setAuthChecked] = useState(false);
  const [adminName, setAdminName] = useState('');
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    if (!getToken()) {
      router.replace('/login');
      return;
    }
    api
      .get('/auth/me')
      .then((json) => {
        if (json.user?.role !== 'admin') {
          setToken(null);
          router.replace('/login');
          return;
        }
        setAdminName(json.user.name);
        setAuthChecked(true);
      })
      .catch(() => {
        setToken(null);
        router.replace('/login');
      });
  }, [router]);

  function signOut() {
    setToken(null);
    router.replace('/login');
  }

  if (!authChecked) {
    return (
      <div style={{ minHeight: '100vh', background: COLORS.bg, color: COLORS.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        Loading…
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', backgroundColor: COLORS.bg, color: COLORS.text, fontFamily: 'system-ui, -apple-system, sans-serif', display: 'flex' }}>
      <aside style={{ width: '260px', backgroundColor: COLORS.panel, borderRight: `1px solid ${COLORS.border}`, padding: '24px 16px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '50%', backgroundColor: COLORS.pink, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '18px' }}>C</div>
            <div>
              <h2 style={{ fontSize: '18px', margin: 0, color: COLORS.pink }}>Chefni AI</h2>
              <span style={{ fontSize: '11px', color: COLORS.blue }}>Admin</span>
            </div>
          </div>
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {[
            { id: 'overview', label: '📊 Overview' },
            { id: 'users', label: '👥 Users' },
            { id: 'revenue', label: '💳 Revenue' },
            { id: 'geo', label: '🌍 Geo-pricing' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              style={{
                textAlign: 'left', padding: '12px 14px', borderRadius: '8px', border: 'none',
                backgroundColor: activeTab === tab.id ? COLORS.pink : 'transparent',
                color: COLORS.text, fontWeight: activeTab === tab.id ? 'bold' : 'normal', cursor: 'pointer',
              }}
            >
              {tab.label}
            </button>
          ))}
        </nav>

        <div style={{ marginTop: 'auto', fontSize: '12px', color: COLORS.muted }}>
          <div>Signed in as {adminName}</div>
          <button onClick={signOut} style={{ marginTop: '8px', background: 'none', border: 'none', color: COLORS.pink, cursor: 'pointer', padding: 0 }}>
            Sign out
          </button>
        </div>
      </aside>

      <main style={{ flex: 1, padding: '32px', overflowY: 'auto' }}>
        {activeTab === 'overview' && <OverviewTab />}
        {activeTab === 'users' && <UsersTab />}
        {activeTab === 'revenue' && <RevenueTab />}
        {activeTab === 'geo' && <GeoPricingTab />}
      </main>
    </div>
  );
}

function Panel({ children }) {
  return <div style={{ background: COLORS.panel, padding: '24px', borderRadius: '16px', border: `1px solid ${COLORS.border}` }}>{children}</div>;
}

function ErrorBox({ message }) {
  return (
    <div style={{ color: '#F87171', background: 'rgba(248,113,113,0.1)', padding: '14px', borderRadius: '10px', marginBottom: '16px' }}>
      {message}
    </div>
  );
}

function useApi(path) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    api
      .get(path)
      .then((json) => {
        if (!cancelled) setData(json.data);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof ApiError ? err.message : 'Something went wrong.');
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [path, reloadKey]);

  return { data, error, loading, reload: () => setReloadKey((k) => k + 1) };
}

function OverviewTab() {
  const { data, error, loading } = useApi('/admin/telemetry');

  return (
    <div>
      <header style={{ marginBottom: '24px' }}>
        <h1 style={{ margin: 0, fontSize: '24px', color: COLORS.pink }}>Platform overview</h1>
        <p style={{ margin: '4px 0 0 0', color: COLORS.muted, fontSize: '14px' }}>Live figures from the Chefni API.</p>
      </header>

      {error && <ErrorBox message={error} />}
      {loading && <div style={{ color: COLORS.muted }}>Loading…</div>}

      {data && (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '28px' }}>
            <Metric label="Total users" value={data.total_users} color={COLORS.blue} />
            <Metric label="Active subscriptions" value={data.active_subscriptions} color={COLORS.pink} />
            <Metric label="Sign-ups today" value={data.signups_today} color={COLORS.green} />
            <Metric label="Total recipes" value={data.total_recipes} color={COLORS.text} />
          </div>

          <Panel>
            <h3 style={{ margin: '0 0 16px 0', color: COLORS.pink }}>Sign-ups, last 7 days</h3>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: '10px', height: '120px' }}>
              {data.signup_trend.map((point) => {
                const max = Math.max(1, ...data.signup_trend.map((p) => p.value));
                return (
                  <div key={point.label} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '6px' }}>
                    <div style={{ width: '100%', height: `${(point.value / max) * 90 + 4}px`, background: COLORS.pink, borderRadius: '4px' }} />
                    <span style={{ fontSize: '11px', color: COLORS.muted }}>{point.label}</span>
                  </div>
                );
              })}
            </div>
          </Panel>
        </>
      )}
    </div>
  );
}

function Metric({ label, value, color }) {
  return (
    <div style={{ background: COLORS.panel, padding: '20px', borderRadius: '12px', border: `1px solid ${COLORS.border}` }}>
      <span style={{ color: COLORS.muted, fontSize: '13px' }}>{label}</span>
      <h2 style={{ fontSize: '28px', color, margin: '8px 0 0 0' }}>{value}</h2>
    </div>
  );
}

function UsersTab() {
  const [search, setSearch] = useState('');
  const { data, error, loading } = useApi(`/admin/users${search ? `?search=${encodeURIComponent(search)}` : ''}`);

  return (
    <div>
      <header style={{ marginBottom: '20px' }}>
        <h1 style={{ margin: 0, fontSize: '24px', color: COLORS.pink }}>Users</h1>
      </header>

      <input
        placeholder="Search by name or email…"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        style={{ marginBottom: '16px', padding: '10px 14px', borderRadius: '8px', border: `1px solid ${COLORS.border}`, background: COLORS.panel, color: COLORS.text, width: '320px' }}
      />

      {error && <ErrorBox message={error} />}
      {loading && <div style={{ color: COLORS.muted }}>Loading…</div>}

      {data && (
        <Panel>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${COLORS.border}`, color: COLORS.blue }}>
                <th style={{ padding: '10px' }}>Name</th>
                <th style={{ padding: '10px' }}>Email</th>
                <th style={{ padding: '10px' }}>Role</th>
                <th style={{ padding: '10px' }}>Plan</th>
                <th style={{ padding: '10px' }}>Joined</th>
              </tr>
            </thead>
            <tbody>
              {data.map((u) => (
                <tr key={u.id} style={{ borderBottom: '1px solid #422332' }}>
                  <td style={{ padding: '10px' }}>{u.name}</td>
                  <td style={{ padding: '10px', color: COLORS.muted }}>{u.email || '—'}</td>
                  <td style={{ padding: '10px' }}>{u.role}</td>
                  <td style={{ padding: '10px' }}>{u.plan}</td>
                  <td style={{ padding: '10px', color: COLORS.muted }}>{u.joined_at ? new Date(u.joined_at).toLocaleDateString() : '—'}</td>
                </tr>
              ))}
              {data.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ padding: '20px', textAlign: 'center', color: COLORS.muted }}>
                    No users found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Panel>
      )}
    </div>
  );
}

function RevenueTab() {
  const { data, error, loading } = useApi('/admin/revenue');

  return (
    <div>
      <header style={{ marginBottom: '20px' }}>
        <h1 style={{ margin: 0, fontSize: '24px', color: COLORS.pink }}>Revenue</h1>
      </header>

      {error && <ErrorBox message={error} />}
      {loading && <div style={{ color: COLORS.muted }}>Loading…</div>}

      {data && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          <Panel>
            <h3 style={{ margin: '0 0 16px 0', color: COLORS.pink }}>Active subscriptions by plan</h3>
            {data.by_plan.map((row) => (
              <div key={row.name} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #422332' }}>
                <span>{row.name}</span>
                <strong>{row.count}</strong>
              </div>
            ))}
            {data.by_plan.length === 0 && <div style={{ color: COLORS.muted }}>No active subscriptions yet.</div>}
          </Panel>
          <Panel>
            <h3 style={{ margin: '0 0 16px 0', color: COLORS.pink }}>Payment gateway split</h3>
            {data.gateway_split.map((row) => (
              <div key={row.name} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #422332' }}>
                <span>{row.name}</span>
                <strong>{row.pct}%</strong>
              </div>
            ))}
            {data.gateway_split.length === 0 && <div style={{ color: COLORS.muted }}>No subscriptions recorded yet.</div>}
          </Panel>
        </div>
      )}
    </div>
  );
}

function GeoPricingTab() {
  const { data, error, loading, reload } = useApi('/admin/geo-pricing');
  const [editing, setEditing] = useState(null);
  const [saveError, setSaveError] = useState(null);
  const [saving, setSaving] = useState(false);

  function startEdit(region) {
    setSaveError(null);
    setEditing({ ...region });
  }

  async function save() {
    setSaving(true);
    setSaveError(null);
    try {
      await api.post('/admin/geo-pricing', {
        country_code: editing.country_code,
        country_name: editing.country_name,
        currency_code: editing.currency_code,
        creator_monthly_price: Number(editing.creator_monthly),
        creator_yearly_price: Number(editing.creator_yearly),
        pro_monthly_price: Number(editing.pro_monthly),
        pro_yearly_price: Number(editing.pro_yearly),
        is_active: editing.is_available,
      });
      setEditing(null);
      reload();
    } catch (err) {
      setSaveError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <header style={{ marginBottom: '20px' }}>
        <h1 style={{ margin: 0, fontSize: '24px', color: COLORS.pink }}>Geo-pricing</h1>
        <p style={{ margin: '4px 0 0 0', color: COLORS.muted, fontSize: '14px' }}>
          Regional subscription pricing, read by the app's paywall.
        </p>
      </header>

      {error && <ErrorBox message={error} />}
      {loading && <div style={{ color: COLORS.muted }}>Loading…</div>}

      {data && (
        <Panel>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${COLORS.border}`, color: COLORS.blue }}>
                <th style={{ padding: '10px' }}>Region</th>
                <th style={{ padding: '10px' }}>Creator /mo</th>
                <th style={{ padding: '10px' }}>Creator /yr</th>
                <th style={{ padding: '10px' }}>Pro /mo</th>
                <th style={{ padding: '10px' }}>Pro /yr</th>
                <th style={{ padding: '10px' }}>Status</th>
                <th style={{ padding: '10px' }} />
              </tr>
            </thead>
            <tbody>
              {data.map((region) => (
                <tr key={region.country_code} style={{ borderBottom: '1px solid #422332' }}>
                  <td style={{ padding: '10px' }}>{region.country_name} ({region.country_code})</td>
                  <td style={{ padding: '10px' }}>{region.symbol}{region.creator_monthly}</td>
                  <td style={{ padding: '10px' }}>{region.symbol}{region.creator_yearly}</td>
                  <td style={{ padding: '10px' }}>{region.symbol}{region.pro_monthly}</td>
                  <td style={{ padding: '10px' }}>{region.symbol}{region.pro_yearly}</td>
                  <td style={{ padding: '10px', color: region.is_available ? COLORS.green : COLORS.muted }}>
                    {region.is_available ? 'Active' : 'Disabled'}
                  </td>
                  <td style={{ padding: '10px' }}>
                    <button onClick={() => startEdit(region)} style={editButtonStyle}>Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>
      )}

      {editing && (
        <div style={overlayStyle}>
          <div style={{ background: COLORS.panel, border: `1px solid ${COLORS.border}`, borderRadius: '16px', padding: '24px', width: '380px' }}>
            <h3 style={{ margin: '0 0 16px 0', color: COLORS.pink }}>
              Edit {editing.country_name}
            </h3>
            {['creator_monthly', 'creator_yearly', 'pro_monthly', 'pro_yearly'].map((field) => (
              <label key={field} style={{ display: 'block', fontSize: '12px', color: COLORS.muted, marginBottom: '10px' }}>
                {field.replace('_', ' ')}
                <input
                  type="number"
                  step="0.01"
                  value={editing[field]}
                  onChange={(e) => setEditing({ ...editing, [field]: e.target.value })}
                  style={inputStyle}
                />
              </label>
            ))}
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', margin: '10px 0' }}>
              <input
                type="checkbox"
                checked={editing.is_available}
                onChange={(e) => setEditing({ ...editing, is_available: e.target.checked })}
              />
              Active
            </label>
            {saveError && <ErrorBox message={saveError} />}
            <div style={{ display: 'flex', gap: '10px', marginTop: '14px' }}>
              <button onClick={() => setEditing(null)} style={{ ...editButtonStyle, flex: 1 }}>Cancel</button>
              <button onClick={save} disabled={saving} style={{ ...primaryButtonStyle, flex: 1 }}>
                {saving ? 'Saving…' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const editButtonStyle = {
  padding: '8px 14px', borderRadius: '8px', border: `1px solid ${COLORS.border}`,
  background: 'transparent', color: COLORS.text, cursor: 'pointer', fontSize: '12.5px',
};

const primaryButtonStyle = {
  padding: '10px 14px', borderRadius: '8px', border: 'none',
  background: COLORS.pink, color: '#fff', cursor: 'pointer', fontWeight: 'bold', fontSize: '13px',
};

const overlayStyle = {
  position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
};

const inputStyle = {
  display: 'block', width: '100%', marginTop: '5px', padding: '9px 11px', borderRadius: '8px',
  border: `1px solid ${COLORS.border}`, background: COLORS.bg, color: COLORS.text,
  fontSize: '13.5px', boxSizing: 'border-box',
};
