/**
 * NebulaGraph instance profiles — the Settings → NebulaGraph section.
 *
 * Renders the named instances of the `dsh-nebula` settings namespace as
 * cards, with add / edit / delete and a default-instance pick. Data flows
 * through the plugin-owned `/dsh-nebula/api` route (the harness's settings
 * RPC does not expose third-party namespaces): the section reads the current
 * view on mount, writes whole-section updates on save, and re-reads when the
 * host broadcasts `settings/document-updated` for this namespace.
 *
 * Copy follows the active locale through the framework `t` seat (dictionary
 * namespace `settings.nebula`, see ./locales.ts).
 */

import { useEffect, useState, type ReactNode } from 'react'
import type { PropsLocale } from '@deepseek-ai/dsh-client-ui-slots'
import type { NebulaInstance, NebulaInstanceSettings } from './nebula-instances.ts'
import {
  CREDENTIAL_REF_PATTERN,
  TLS_LABELS,
  draftFrom,
  normalizeSettings,
  validateDraft,
  type InstanceDraft,
} from './nebula-instances.ts'
import type { InstancesView } from './instances-api.ts'
import type { NebulaLocaleKey } from './locales.ts'

/** Business face injected by the slot registration. */
export interface NebulaInstancesSectionInjected {
  /** Read the current namespace view. */
  load: () => Promise<InstancesView>
  /** Replace the section; revision fences stale writes. */
  update: (section: NebulaInstanceSettings, revision?: number) => Promise<InstancesView>
  /** Observe host-side document updates for this namespace. */
  subscribe: (listener: () => void) => () => void
  /** Report configured/writable state for each credential reference. */
  describeCredentials: (refs: string[]) => Promise<Array<{ ref: string; configured: boolean; writable: boolean }>>
  /** Write a credential value through the Host (values never return). */
  setCredential: (ref: string, value: string) => Promise<boolean>
  /** Remove a credential value. */
  unsetCredential: (ref: string) => Promise<boolean>
  /** Observe Host-side credential changes. */
  subscribeCredentials: (listener: () => void) => () => void
}

/** Full props bound by the settings slot renderer. */
export type NebulaInstancesSectionProps =
  NebulaInstancesSectionInjected
  & PropsLocale<'settings.nebula'>
  & { close: () => void }

type ViewState =
  | { readonly status: 'loading' }
  | { readonly status: 'error'; readonly message: string }
  | { readonly status: 'ready'; readonly view: InstancesView }

type EditorState =
  | { kind: 'closed' }
  | { kind: 'new' }
  | { kind: 'edit'; alias: string }

/** One text field in the editor form. */
function Field(props: {
  label: string
  value: string
  onChange: (value: string) => void
  placeholder?: string
  required?: boolean
  wide?: boolean
  secret?: boolean
}): ReactNode {
  return (
    <label style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: props.wide === true ? '1 1 100%' : '1 1 0', minWidth: props.wide === true ? 0 : 150 }}>
      <span style={{ fontSize: 12, color: '#9aa4b2' }}>
        {props.label}{props.required === true ? ' *' : ''}
      </span>
      <input
        type={props.secret === true ? 'password' : 'text'}
        value={props.value}
        placeholder={props.placeholder ?? ''}
        spellCheck={false}
        autoComplete="off"
        onChange={(event) => { props.onChange(event.currentTarget.value) }}
        style={{
          background: '#12151c',
          border: '1px solid #2a3140',
          borderRadius: 6,
          padding: '6px 8px',
          color: '#d8dee9',
          fontSize: 13,
          fontFamily: 'inherit',
          outline: 'none',
        }}
      />
    </label>
  )
}

/** One instance card: alias, endpoint summary, default star, actions. */
function InstanceCard(props: {
  instance: NebulaInstance
  isDefault: boolean
  confirming: boolean
  t: (key: NebulaLocaleKey, params?: Record<string, unknown>) => string
  onConfirmingChange: (value: boolean) => void
  onEdit: () => void
  onDelete: () => void
  onSetDefault: () => void
}): ReactNode {
  const { instance, isDefault, t } = props
  const summary = [
    instance.host,
    instance.port !== undefined ? `:${String(instance.port)}` : '',
    instance.user !== undefined ? ` · ${instance.user}` : '',
    instance.tls !== undefined ? ` · tls: ${instance.tls}` : '',
    instance.passwordRef !== undefined ? ` · ${t('fieldPasswordRef')}: ${instance.passwordRef}` : '',
  ].join('')
  return (
    <div style={{
      border: `1px solid ${isDefault ? '#5B8FF9' : '#2a3140'}`,
      borderRadius: 8,
      padding: '10px 12px',
      background: '#1b212c',
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
        <span style={{ fontWeight: 600, color: '#d8dee9', fontSize: 14 }}>
          {isDefault ? '⭐ ' : ''}{instance.alias}
        </span>
        {isDefault
          ? <span style={{ fontSize: 11, color: '#5B8FF9', border: '1px solid #5B8FF9', borderRadius: 4, padding: '1px 6px' }}>{t('defaultBadge')}</span>
          : null}
        <span style={{ fontSize: 12, color: '#9aa4b2' }}>{summary}</span>
      </div>
      {instance.note !== undefined && instance.note !== ''
        ? <span style={{ fontSize: 12, color: '#9aa4b2' }}>{instance.note}</span>
        : null}
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        {!isDefault
          ? <CardButton onClick={props.onSetDefault}>{t('setDefault')}</CardButton>
          : <CardButton onClick={props.onSetDefault} disabled>{t('isDefault')}</CardButton>}
        <CardButton onClick={props.onEdit}>{t('edit')}</CardButton>
        {props.confirming
          ? (
            <span style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
              <CardButton tone="danger" onClick={props.onDelete}>{t('confirmDelete')}</CardButton>
              <CardButton onClick={() => { props.onConfirmingChange(false) }}>{t('cancel')}</CardButton>
            </span>
          )
          : <CardButton tone="danger" onClick={() => { props.onConfirmingChange(true) }}>{t('delete')}</CardButton>}
      </div>
    </div>
  )
}

/** Small card-level action button. */
function CardButton(props: {
  children: ReactNode
  onClick: () => void
  tone?: 'default' | 'danger'
  disabled?: boolean
}): ReactNode {
  const danger = props.tone === 'danger'
  return (
    <button
      type="button"
      onClick={props.onClick}
      disabled={props.disabled === true}
      style={{
        cursor: props.disabled === true ? 'not-allowed' : 'pointer',
        background: 'transparent',
        color: danger ? '#E8684A' : '#8ab4ff',
        border: `1px solid ${danger ? '#E8684A' : '#3a4a63'}`,
        borderRadius: 6,
        padding: '3px 10px',
        fontSize: 12,
        opacity: props.disabled === true ? 0.4 : 1,
      }}
    >
      {props.children}
    </button>
  )
}

/** One credential state row: reference, configured badge, write / clear / remove. */
function CredentialRow(props: {
  reference: string
  configured: boolean
  writable: boolean
  removable: boolean
  draft: string
  busy: boolean
  t: (key: NebulaLocaleKey, params?: Record<string, unknown>) => string
  onDraftChange: (value: string) => void
  onSave: () => void
  onClear: () => void
  onRemove: () => void
}): ReactNode {
  const { reference: ref, configured, writable, removable, draft, busy, t } = props
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
      <code style={{ color: '#d8dee9', background: '#12151c', borderRadius: 4, padding: '3px 6px', fontSize: 12 }}>{ref}</code>
      <span
        style={{
          fontSize: 11,
          color: configured ? '#5AD8A6' : '#F6BD16',
          border: `1px solid ${configured ? '#5AD8A6' : '#F6BD16'}`,
          borderRadius: 4,
          padding: '1px 6px',
        }}
      >
        {configured ? t('credConfigured') : t('credMissing')}
      </span>
      <input
        type="password"
        value={draft}
        placeholder={t('credValuePlaceholder')}
        autoComplete="off"
        spellCheck={false}
        disabled={!writable || busy}
        onChange={(event) => { props.onDraftChange(event.currentTarget.value) }}
        style={{
          flex: '1 1 220px',
          background: '#12151c',
          border: '1px solid #2a3140',
          borderRadius: 6,
          padding: '5px 8px',
          color: '#d8dee9',
          fontSize: 12,
          outline: 'none',
        }}
      />
      <CardButton onClick={props.onSave} disabled={!writable || busy || draft.trim() === ''}>
        {t('credSave')}
      </CardButton>
      <CardButton tone="danger" onClick={props.onClear} disabled={!writable || busy || !configured}>
        {t('credClear')}
      </CardButton>
      {removable
        ? <CardButton tone="danger" onClick={props.onRemove} disabled={busy}>{t('credRemove')}</CardButton>
        : null}
    </div>
  )
}

/**
 * The credential management panel: set / clear the values behind the
 * passwordRefs the instances (and the extra references) name. Values live in
 * the DSH credentials document; this page only ever learns whether one is
 * configured — the password inputs are write-only and never pre-filled.
 */
function CredentialsPanel(props: {
  refs: string[]
  removableRefs: string[]
  writable: boolean
  t: (key: NebulaLocaleKey, params?: Record<string, unknown>) => string
  describeCredentials: (refs: string[]) => Promise<Array<{ ref: string; configured: boolean; writable: boolean }>>
  setCredential: (ref: string, value: string) => Promise<boolean>
  unsetCredential: (ref: string) => Promise<boolean>
  subscribeCredentials: (listener: () => void) => () => void
  onAddExtra: (ref: string) => Promise<string | undefined>
  onRemoveExtra: (ref: string) => Promise<string | undefined>
}): ReactNode {
  const {
    refs, removableRefs, writable, t, describeCredentials, setCredential, unsetCredential,
    subscribeCredentials, onAddExtra, onRemoveExtra,
  } = props
  const [states, setStates] = useState<Record<string, { configured: boolean; writable: boolean }>>({})
  const [drafts, setDrafts] = useState<Record<string, string>>({})
  const [busy, setBusy] = useState<Record<string, boolean>>({})
  const [adding, setAdding] = useState(false)
  const [newRef, setNewRef] = useState('')
  const [error, setError] = useState<string | undefined>(undefined)

  const refsKey = refs.join('\0')

  useEffect(() => {
    let current = true
    const refresh = (): void => {
      void describeCredentials(refs).then(
        (entries) => {
          if (!current) return
          const next: Record<string, { configured: boolean; writable: boolean }> = {}
          for (const entry of entries) next[entry.ref] = { configured: entry.configured, writable: entry.writable }
          setStates(next)
        },
        () => { /* keep the last known states; a write still reaches the Host */ },
      )
    }
    refresh()
    const off = subscribeCredentials(refresh)
    return () => { current = false; off() }
  }, [describeCredentials, subscribeCredentials, refsKey])

  const setDraft = (ref: string, value: string): void => {
    setDrafts((current) => ({ ...current, [ref]: value }))
    setError(undefined)
  }

  const saveCredential = async (ref: string): Promise<void> => {
    const value = (drafts[ref] ?? '').trim()
    if (value === '') {
      setError(t('credValueRequired'))
      return
    }
    setBusy((current) => ({ ...current, [ref]: true }))
    setError(undefined)
    const ok = await setCredential(ref, value)
    setBusy((current) => ({ ...current, [ref]: false }))
    if (ok) {
      setDrafts((current) => ({ ...current, [ref]: '' }))
      setStates((current) => ({ ...current, [ref]: { configured: true, writable: current[ref]?.writable ?? true } }))
    } else {
      setError(t('saveFailed'))
    }
  }

  const clearCredential = async (ref: string): Promise<void> => {
    setBusy((current) => ({ ...current, [ref]: true }))
    setError(undefined)
    const ok = await unsetCredential(ref)
    setBusy((current) => ({ ...current, [ref]: false }))
    if (ok) {
      setStates((current) => ({ ...current, [ref]: { configured: false, writable: current[ref]?.writable ?? true } }))
    } else {
      setError(t('saveFailed'))
    }
  }

  const addExtra = async (): Promise<void> => {
    const ref = newRef.trim()
    if (!CREDENTIAL_REF_PATTERN.test(ref)) {
      setError(t('refInvalid'))
      return
    }
    if (refs.includes(ref)) {
      setError(t('refExists'))
      return
    }
    setError(undefined)
    const failure = await onAddExtra(ref)
    if (failure !== undefined) {
      setError(failure)
      return
    }
    setNewRef('')
    setAdding(false)
  }

  const removeExtra = async (ref: string): Promise<void> => {
    setError(undefined)
    const failure = await onRemoveExtra(ref)
    if (failure !== undefined) setError(failure)
  }

  return (
    <div style={{ border: '1px solid #2a3140', borderRadius: 8, padding: 12, background: '#1b212c', display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div>
        <span style={{ fontWeight: 600, color: '#d8dee9', fontSize: 14 }}>{t('credentialsTitle')}</span>
        <p style={{ margin: '4px 0 0', fontSize: 12, color: '#9aa4b2', lineHeight: 1.5 }}>{t('credentialsHint')}</p>
      </div>
      {refs.length === 0 ? (
        <p style={{ margin: 0, fontSize: 12, color: '#9aa4b2' }}>{t('credEmpty')}</p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {refs.map((ref) => {
            const state = states[ref] ?? { configured: false, writable: true }
            return (
              <CredentialRow
                key={ref}
                reference={ref}
                configured={state.configured}
                writable={writable && state.writable}
                removable={removableRefs.includes(ref)}
                draft={drafts[ref] ?? ''}
                busy={busy[ref] === true}
                t={t}
                onDraftChange={(value) => { setDraft(ref, value) }}
                onSave={() => { void saveCredential(ref) }}
                onClear={() => { void clearCredential(ref) }}
                onRemove={() => { void removeExtra(ref) }}
              />
            )
          })}
        </div>
      )}
      {adding
        ? (
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
            <input
              type="text"
              value={newRef}
              placeholder={t('credRefPlaceholder')}
              autoFocus
              spellCheck={false}
              onChange={(event) => { setNewRef(event.currentTarget.value); setError(undefined) }}
              onKeyDown={(event) => {
                if (event.key === 'Enter') { event.preventDefault(); void addExtra() }
              }}
              style={{
                flex: '1 1 220px',
                background: '#12151c',
                border: '1px solid #2a3140',
                borderRadius: 6,
                padding: '5px 8px',
                color: '#d8dee9',
                fontSize: 12,
                outline: 'none',
              }}
            />
            <button
              type="button"
              disabled={!writable || newRef.trim() === ''}
              onClick={() => { void addExtra() }}
              style={{
                cursor: !writable || newRef.trim() === '' ? 'not-allowed' : 'pointer',
                background: '#5B8FF9',
                color: '#0b0e14',
                border: 'none',
                borderRadius: 6,
                padding: '5px 12px',
                fontSize: 12,
                fontWeight: 600,
                opacity: !writable || newRef.trim() === '' ? 0.5 : 1,
              }}
            >
              {t('save')}
            </button>
            <CardButton onClick={() => { setAdding(false); setNewRef(''); setError(undefined) }}>{t('cancel')}</CardButton>
          </div>
        )
        : writable
          ? (
            <div>
              <button
                type="button"
                onClick={() => { setAdding(true) }}
                style={{
                  cursor: 'pointer',
                  background: 'transparent',
                  color: '#8ab4ff',
                  border: '1px dashed #3a4a63',
                  borderRadius: 6,
                  padding: '5px 12px',
                  fontSize: 12,
                }}
              >
                + {t('credAdd')}
              </button>
            </div>
          )
          : null}
      {error !== undefined
        ? <p role="alert" style={{ margin: 0, fontSize: 12, color: '#E8684A' }}>{error}</p>
        : null}
    </div>
  )
}

/** The NebulaGraph instance profiles page. */
export function NebulaInstancesSection(props: NebulaInstancesSectionProps): ReactNode {
  const {
    load, update, subscribe, t,
    describeCredentials, setCredential, unsetCredential, subscribeCredentials,
  } = props
  const [state, setState] = useState<ViewState>({ status: 'loading' })
  const [editor, setEditor] = useState<EditorState>({ kind: 'closed' })
  const [draft, setDraft] = useState<InstanceDraft>(() => draftFrom(undefined))
  const [draftError, setDraftError] = useState<string | undefined>(undefined)
  const [saving, setSaving] = useState(false)
  const [confirmingAlias, setConfirmingAlias] = useState<string | null>(null)

  useEffect(() => {
    let current = true
    const reload = (): void => {
      void load().then(
        (view) => { if (current) setState({ status: 'ready', view }) },
        (error: unknown) => {
          if (!current) return
          setState({
            status: 'error',
            message: error instanceof Error ? error.message : String(error),
          })
        },
      )
    }
    reload()
    const off = subscribe(reload)
    return () => { current = false; off() }
  }, [load, subscribe])

  if (state.status === 'loading') {
    return <p style={{ color: '#9aa4b2', fontSize: 13 }}>{t('loading')}</p>
  }
  if (state.status === 'error') {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <p role="alert" style={{ margin: 0, fontSize: 13, color: '#E8684A' }}>
          {t('errorTitle', { message: state.message })}
        </p>
        <p style={{ margin: 0, fontSize: 12, color: '#9aa4b2' }}>
          {t('errorHint')}
        </p>
      </div>
    )
  }

  const view = state.view
  const settings = normalizeSettings(view.value)
  const instances = settings.instances
  const defaultInstance = settings.defaultInstance
  const writable = view.writable === true

  const setDraftField = (key: keyof InstanceDraft) => (value: string): void => {
    setDraft((current) => ({ ...current, [key]: value }))
    setDraftError(undefined)
  }

  const beginNew = (): void => {
    setDraft(draftFrom(undefined))
    setDraftError(undefined)
    setEditor({ kind: 'new' })
  }

  const beginEdit = (instance: NebulaInstance): void => {
    setDraft(draftFrom(instance))
    setDraftError(undefined)
    setEditor({ kind: 'edit', alias: instance.alias })
  }

  const cancelEdit = (): void => {
    setEditor({ kind: 'closed' })
    setDraftError(undefined)
  }

  /** Build the next whole section and commit it through the API. */
  const commitSection = async (next: NebulaInstanceSettings): Promise<void> => {
    setSaving(true)
    setDraftError(undefined)
    try {
      const fresh = await update(next, view.revision)
      setState({ status: 'ready', view: fresh })
      setEditor({ kind: 'closed' })
      setConfirmingAlias(null)
    } catch (error) {
      setDraftError(error instanceof Error ? error.message : t('saveFailed'))
    } finally {
      setSaving(false)
    }
  }

  const saveDraft = async (): Promise<void> => {
    if (saving || state.status !== 'ready') return
    const result = validateDraft(draft)
    if (!result.ok) {
      setDraftError(t(result.code as NebulaLocaleKey))
      return
    }
    const instance = result.instance
    if (editor.kind === 'new' && instances.some((item) => item.alias === instance.alias)) {
      setDraftError(t('aliasExists', { alias: instance.alias }))
      return
    }
    if (editor.kind === 'edit' && instance.alias !== editor.alias
      && instances.some((item) => item.alias !== editor.alias && item.alias === instance.alias)) {
      setDraftError(t('aliasExists', { alias: instance.alias }))
      return
    }
    const next = editor.kind === 'edit'
      ? instances.map((item) => item.alias === editor.alias ? instance : item)
      : [...instances, instance]
    // The default alias follows a renamed default instance.
    const nextDefault = defaultInstance !== undefined
      && (editor.kind === 'edit' && editor.alias === defaultInstance)
      ? instance.alias
      : defaultInstance
    await commitSection({ instances: next, defaultInstance: nextDefault ?? '' })
  }

  const removeInstance = async (alias: string): Promise<void> => {
    if (saving || state.status !== 'ready') return
    const next = instances.filter((item) => item.alias !== alias)
    await commitSection({
      instances: next,
      defaultInstance: defaultInstance === alias ? '' : (defaultInstance ?? ''),
    })
  }

  const setDefault = async (alias: string): Promise<void> => {
    if (saving || state.status !== 'ready') return
    await commitSection({ instances, defaultInstance: alias })
  }

  /** Replace the section (credential-extras edits); returns an error or undefined. */
  const saveExtras = async (next: NebulaInstanceSettings): Promise<string | undefined> => {
    if (state.status !== 'ready') return t('saveFailed')
    setSaving(true)
    try {
      const fresh = await update(next, view.revision)
      setState({ status: 'ready', view: fresh })
      return undefined
    } catch (error) {
      return error instanceof Error ? error.message : t('saveFailed')
    } finally {
      setSaving(false)
    }
  }

  const addCredentialRef = async (ref: string): Promise<string | undefined> => {
    return saveExtras({
      instances,
      defaultInstance: defaultInstance ?? '',
      credentialRefs: [...credentialRefs, ref],
    })
  }

  const removeCredentialRef = async (ref: string): Promise<string | undefined> => {
    return saveExtras({
      instances,
      defaultInstance: defaultInstance ?? '',
      credentialRefs: credentialRefs.filter((item) => item !== ref),
    })
  }

  const editing = editor.kind !== 'closed'
  // Every credential reference worth managing: the instances' passwordRefs
  // plus the extras persisted in the section (deduped, order-stable).
  const credentialRefs = settings.credentialRefs ?? []
  const credentialRows: string[] = []
  for (const instance of instances) {
    if (instance.passwordRef !== undefined && instance.passwordRef !== '' && !credentialRows.includes(instance.passwordRef)) {
      credentialRows.push(instance.passwordRef)
    }
  }
  for (const ref of credentialRefs) {
    if (!credentialRows.includes(ref)) credentialRows.push(ref)
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14, maxWidth: 720 }}>
      <div>
        <p style={{ margin: 0, fontSize: 13, color: '#9aa4b2', lineHeight: 1.6 }}>
          {t('description1')}
          <code style={{ color: '#8ab4ff', background: '#12151c', borderRadius: 4, padding: '1px 5px' }}>nebula_connect(instance: "prod")</code>
          {t('description2')}
        </p>
      </div>

      {!writable ? (
        <p style={{ margin: 0, fontSize: 12, color: '#F6BD16' }} role="status">
          {t('readOnly')}
        </p>
      ) : null}

      {instances.length === 0 && !editing ? (
        <p style={{ margin: 0, fontSize: 13, color: '#9aa4b2' }}>
          {t('empty')}
        </p>
      ) : null}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {instances.map((instance) => (
          <InstanceCard
            key={instance.alias}
            instance={instance}
            isDefault={instance.alias === defaultInstance}
            confirming={confirmingAlias === instance.alias}
            t={t}
            onConfirmingChange={(value) => { setConfirmingAlias(value ? instance.alias : null) }}
            onEdit={() => { beginEdit(instance) }}
            onDelete={() => { void removeInstance(instance.alias) }}
            onSetDefault={() => { void setDefault(instance.alias) }}
          />
        ))}
      </div>

      {editor.kind === 'new' || editor.kind === 'edit' ? (
        <div style={{
          border: '1px solid #5B8FF9',
          borderRadius: 8,
          padding: 12,
          background: '#161c26',
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
        }}>
          <span style={{ fontWeight: 600, color: '#d8dee9', fontSize: 14 }}>
            {editor.kind === 'new'
              ? t('addTitle')
              : t('editTitle', { alias: editor.alias })}
          </span>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <Field label={t('fieldAlias')} required value={draft.alias} onChange={setDraftField('alias')} placeholder={t('aliasPlaceholder')} />
            <Field label={t('fieldHost')} required value={draft.host} onChange={setDraftField('host')} placeholder={t('hostPlaceholder')} />
            <Field label={t('fieldPort')} value={draft.port} onChange={setDraftField('port')} placeholder={t('portPlaceholder')} />
            <Field label={t('fieldUser')} value={draft.user} onChange={setDraftField('user')} placeholder={t('userPlaceholder')} />
          </div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <Field label={t('fieldPasswordRef')} wide value={draft.passwordRef} onChange={setDraftField('passwordRef')} placeholder={t('passwordRefPlaceholder')} />
          </div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <label style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <span style={{ fontSize: 12, color: '#9aa4b2' }}>{t('fieldTls')}</span>
              <select
                value={draft.tls}
                onChange={(event) => { setDraftField('tls')(event.currentTarget.value) }}
                style={{ background: '#12151c', border: '1px solid #2a3140', borderRadius: 6, padding: '6px 8px', color: '#d8dee9', fontSize: 13, outline: 'none' }}
              >
                <option value="auto">{TLS_LABELS.auto}</option>
                <option value="on">{TLS_LABELS.on}</option>
                <option value="off">{TLS_LABELS.off}</option>
              </select>
            </label>
            <Field label={t('fieldTimeoutMs')} value={draft.timeoutMs} onChange={setDraftField('timeoutMs')} placeholder={t('timeoutPlaceholder')} />
            <Field label={t('fieldNote')} wide value={draft.note} onChange={setDraftField('note')} placeholder={t('notePlaceholder')} />
          </div>
          <details style={{ fontSize: 13, color: '#9aa4b2' }}>
            <summary style={{ cursor: 'pointer', color: '#8ab4ff' }}>{t('advancedTls')}</summary>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginTop: 8 }}>
              <Field label={t('fieldCa')} wide value={draft.ca} onChange={setDraftField('ca')} placeholder={t('caPlaceholder')} />
              <Field label={t('fieldCert')} wide value={draft.cert} onChange={setDraftField('cert')} placeholder={t('caPlaceholder')} />
              <Field label={t('fieldKey')} wide secret value={draft.key} onChange={setDraftField('key')} placeholder={t('keyPlaceholder')} />
              <Field label={t('fieldServername')} wide value={draft.servername} onChange={setDraftField('servername')} placeholder="nebula.example.com" />
            </div>
          </details>
          {draftError !== undefined
            ? <p role="alert" style={{ margin: 0, fontSize: 12, color: '#E8684A' }}>{draftError}</p>
            : null}
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <button
              type="button"
              disabled={saving || !writable}
              onClick={() => { void saveDraft() }}
              style={{
                cursor: saving || !writable ? 'not-allowed' : 'pointer',
                background: '#5B8FF9',
                color: '#0b0e14',
                border: 'none',
                borderRadius: 6,
                padding: '6px 16px',
                fontSize: 13,
                fontWeight: 600,
                opacity: saving || !writable ? 0.5 : 1,
              }}
            >
              {t(saving ? 'saving' : 'save')}
            </button>
            <CardButton onClick={cancelEdit}>{t('cancel')}</CardButton>
          </div>
        </div>
      ) : null}

      {writable && !editing ? (
        <div>
          <button
            type="button"
            onClick={beginNew}
            style={{
              cursor: 'pointer',
              background: 'transparent',
              color: '#8ab4ff',
              border: '1px dashed #3a4a63',
              borderRadius: 8,
              padding: '8px 14px',
              fontSize: 13,
              width: '100%',
            }}
          >
            {t('addButton')}
          </button>
        </div>
      ) : null}

      <CredentialsPanel
        refs={credentialRows}
        removableRefs={credentialRefs}
        writable={writable}
        t={t}
        describeCredentials={describeCredentials}
        setCredential={setCredential}
        unsetCredential={unsetCredential}
        subscribeCredentials={subscribeCredentials}
        onAddExtra={(ref) => addCredentialRef(ref)}
        onRemoveExtra={(ref) => removeCredentialRef(ref)}
      />
    </div>
  )
}
