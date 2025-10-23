<script>
  let { segments = [] } = $props()
  let uploading = $state(false)
  let fileInput
  let fileInputLimit
  let searchTerm = $state('')
  let sortColumn = $state(null)
  let sortDirection = $state('asc')

  async function handleUpload(limit = null) {
    const file = limit ? fileInputLimit.files[0] : fileInput.files[0]
    if (!file) return

    const formData = new FormData()
    formData.append('file', file)
    if (limit) {
      formData.append('limit', limit)
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    uploading = true
    try {
      await fetch('/swb/segments/upload', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken
        },
        body: formData
      })
      window.location.reload()
    } catch (error) {
      console.error('Upload failed:', error)
      alert('Upload failed. Please try again.')
    } finally {
      uploading = false
      if (fileInput) fileInput.value = ''
      if (fileInputLimit) fileInputLimit.value = ''
    }
  }

  function handleSort(column) {
    if (sortColumn === column) {
      sortDirection = sortDirection === 'asc' ? 'desc' : 'asc'
    } else {
      sortColumn = column
      sortDirection = 'asc'
    }
  }

  async function handleDeleteAll() {
    if (!confirm(`Are you sure you want to delete all ${segments.length} segments? This cannot be undone.`)) {
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    try {
      await fetch('/swb/segments/delete_all', {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': csrfToken
        }
      })
      window.location.reload()
    } catch (error) {
      console.error('Delete failed:', error)
      alert('Delete failed. Please try again.')
    }
  }

  let filteredAndSortedSegments = $derived.by(() => {
    let result = [...segments]

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      result = result.filter(segment =>
        (segment.filename?.toLowerCase().includes(term)) ||
        (segment.channel?.toLowerCase().includes(term)) ||
        (segment.text?.toLowerCase().includes(term)) ||
        (segment.beg?.toString().includes(term)) ||
        (segment.end?.toString().includes(term)) ||
        (segment.turn?.toString().includes(term))
      )
    }

    // Sort
    if (sortColumn) {
      result.sort((a, b) => {
        let aVal = a[sortColumn]
        let bVal = b[sortColumn]

        // Handle null/undefined values
        if (aVal == null) aVal = ''
        if (bVal == null) bVal = ''

        // Convert to string for comparison
        aVal = aVal.toString().toLowerCase()
        bVal = bVal.toString().toLowerCase()

        if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1
        if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1
        return 0
      })
    }

    return result
  })
</script>

<div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-4xl font-bold text-slate-900 mb-2">Segment Data</h1>
        <p class="text-slate-600">Manage and view segment information</p>
      </div>

      {#if segments.length === 0}
        <div class="flex gap-3">
          <label class="upload-btn cursor-pointer">
            <input
              type="file"
              accept=".sqlite,.sqlite3,.db"
              bind:this={fileInputLimit}
              onchange={() => handleUpload(1000)}
              disabled={uploading}
              class="hidden"
            />
            <svg class="upload-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            <span>{uploading ? 'Uploading...' : 'Upload 1000 Rows'}</span>
          </label>
          <label class="upload-btn-secondary cursor-pointer">
            <input
              type="file"
              accept=".sqlite,.sqlite3,.db"
              bind:this={fileInput}
              onchange={() => handleUpload()}
              disabled={uploading}
              class="hidden"
            />
            <svg class="upload-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            <span>{uploading ? 'Uploading...' : 'Upload All'}</span>
          </label>
        </div>
      {:else}
        <div class="flex gap-3">
          <button onclick={handleDeleteAll} class="delete-btn">
            <svg class="upload-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            <span>Delete All</span>
          </button>
          <div class="upload-disabled">
            <svg class="upload-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            <span>Upload Locked</span>
          </div>
        </div>
      {/if}
    </div>

    {#if segments.length === 0}
      <div class="empty-state">
        <svg class="empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <h3 class="text-xl font-semibold text-slate-700 mb-2">No Segments Yet</h3>
        <p class="text-slate-500 mb-6">Upload a SQLite database to import segment data</p>
      </div>
    {:else}
      <!-- Search and Stats -->
      <div class="mb-6 flex gap-4 items-center">
        <div class="search-container flex-1">
          <svg class="search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            bind:value={searchTerm}
            placeholder="Search segments..."
            class="search-input"
          />
        </div>

        <div class="stats-card">
          <div class="stat">
            <div class="stat-label">Showing</div>
            <div class="stat-value">{filteredAndSortedSegments.length} / {segments.length}</div>
          </div>
        </div>
      </div>

      <!-- Table -->
      <div class="table-container">
        <div class="overflow-x-auto">
          <table class="data-table">
            <thead>
              <tr>
                <th onclick={() => handleSort('filename')} class="sortable">
                  <div class="th-content">
                    <span>Filename</span>
                    {#if sortColumn === 'filename'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
                <th onclick={() => handleSort('channel')} class="sortable">
                  <div class="th-content">
                    <span>Channel</span>
                    {#if sortColumn === 'channel'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
                <th onclick={() => handleSort('beg')} class="sortable">
                  <div class="th-content">
                    <span>Begin</span>
                    {#if sortColumn === 'beg'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
                <th onclick={() => handleSort('end')} class="sortable">
                  <div class="th-content">
                    <span>End</span>
                    {#if sortColumn === 'end'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
                <th onclick={() => handleSort('turn')} class="sortable">
                  <div class="th-content">
                    <span>Turn</span>
                    {#if sortColumn === 'turn'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
                <th onclick={() => handleSort('text')} class="sortable">
                  <div class="th-content">
                    <span>Text</span>
                    {#if sortColumn === 'text'}
                      <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {#if sortDirection === 'asc'}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        {:else}
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        {/if}
                      </svg>
                    {/if}
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              {#each filteredAndSortedSegments as segment, idx}
                <tr class:even-row={idx % 2 === 1}>
                  <td>
                    {#if segment.filename}
                      <a href="/swb/files/{encodeURIComponent(segment.filename)}" class="filename-link">
                        {segment.filename}
                      </a>
                    {:else}
                      -
                    {/if}
                  </td>
                  <td>
                    <span class="badge">{segment.channel || '-'}</span>
                  </td>
                  <td>{segment.beg?.toFixed(2) || '-'}</td>
                  <td>{segment.end?.toFixed(2) || '-'}</td>
                  <td>{segment.turn || '-'}</td>
                  <td class="max-w-md truncate">{segment.text || '-'}</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </div>
    {/if}
  </div>
</div>

<style>
  .upload-btn {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: #2563eb;
    color: white;
    border-radius: 0.5rem;
    font-weight: 500;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    transition: all 0.2s;
  }

  .upload-btn:hover {
    background: #1d4ed8;
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  }

  .upload-btn:disabled {
    background: #94a3b8;
    cursor: not-allowed;
    transform: none;
  }

  .upload-icon {
    width: 1.25rem;
    height: 1.25rem;
    flex-shrink: 0;
  }

  .empty-state {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    text-align: center;
    padding: 4rem 2rem;
  }

  .empty-icon {
    width: 3rem;
    height: 3rem;
    margin: 0 auto 1rem;
    color: #cbd5e1;
  }

  .stats-card {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    padding: 1.5rem;
  }

  .stat {
    text-align: center;
  }

  .stat-label {
    font-size: 0.875rem;
    font-weight: 500;
    color: #64748b;
    margin-bottom: 0.25rem;
  }

  .stat-value {
    font-size: 1.875rem;
    font-weight: 700;
    color: #2563eb;
  }

  .table-container {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    overflow: hidden;
  }

  .data-table {
    width: 100%;
    border-collapse: collapse;
  }

  .data-table thead {
    background: linear-gradient(to right, #f8fafc, #f1f5f9);
    border-bottom: 1px solid #e2e8f0;
  }

  .data-table th {
    padding: 1rem 1.5rem;
    text-align: left;
    font-size: 0.75rem;
    font-weight: 600;
    color: #334155;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .data-table tbody tr {
    transition: background-color 0.15s;
  }

  .data-table tbody tr:hover {
    background: #eff6ff;
  }

  .data-table tbody tr:nth-child(even) {
    background: #f8fafc;
  }

  .data-table tbody tr:nth-child(even):hover {
    background: #eff6ff;
  }

  .data-table td {
    padding: 1rem 1.5rem;
    font-size: 0.875rem;
    color: #475569;
    border-top: 1px solid #f1f5f9;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.625rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 500;
    background: #f1f5f9;
    color: #1e293b;
    border: 1px solid #e2e8f0;
  }

  .upload-disabled {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: #e2e8f0;
    color: #64748b;
    border-radius: 0.5rem;
    font-weight: 500;
    border: 1px solid #cbd5e1;
    cursor: not-allowed;
  }

  .search-container {
    position: relative;
  }

  .search-icon {
    position: absolute;
    left: 1rem;
    top: 50%;
    transform: translateY(-50%);
    width: 1.25rem;
    height: 1.25rem;
    color: #94a3b8;
    pointer-events: none;
  }

  .search-input {
    width: 100%;
    padding: 0.75rem 1rem 0.75rem 3rem;
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
    font-size: 0.875rem;
    background: white;
    transition: all 0.2s;
  }

  .search-input:focus {
    outline: none;
    border-color: #2563eb;
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
  }

  .sortable {
    cursor: pointer;
    user-select: none;
  }

  .sortable:hover {
    background: #e2e8f0;
  }

  .th-content {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    justify-content: space-between;
  }

  .sort-icon {
    width: 1rem;
    height: 1rem;
    flex-shrink: 0;
  }

  .delete-btn {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: #dc2626;
    color: white;
    border-radius: 0.5rem;
    font-weight: 500;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    transition: all 0.2s;
    border: none;
    cursor: pointer;
  }

  .delete-btn:hover {
    background: #b91c1c;
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  }

  .upload-btn-secondary {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: white;
    color: #2563eb;
    border: 2px solid #2563eb;
    border-radius: 0.5rem;
    font-weight: 500;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    transition: all 0.2s;
  }

  .upload-btn-secondary:hover {
    background: #eff6ff;
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  }

  .upload-btn-secondary:disabled {
    background: #f8fafc;
    color: #94a3b8;
    border-color: #cbd5e1;
    cursor: not-allowed;
    transform: none;
  }

  .filename-link {
    color: #2563eb;
    font-weight: 600;
    text-decoration: none;
    transition: color 0.2s;
  }

  .filename-link:hover {
    color: #1d4ed8;
    text-decoration: underline;
  }
</style>
