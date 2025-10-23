<script>
  let { files = [] } = $props()
  let searchTerm = $state('')
  let sortDirection = $state('asc')

  function toggleSort() {
    sortDirection = sortDirection === 'asc' ? 'desc' : 'asc'
  }

  let filteredAndSortedFiles = $derived.by(() => {
    let result = [...files]

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      result = result.filter(file =>
        file.filename?.toLowerCase().includes(term)
      )
    }

    // Sort
    result.sort((a, b) => {
      let aVal = a.filename || ''
      let bVal = b.filename || ''

      aVal = aVal.toLowerCase()
      bVal = bVal.toLowerCase()

      if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1
      if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1
      return 0
    })

    return result
  })
</script>

<div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-4xl font-bold text-slate-900 mb-2">Files</h1>
        <p class="text-slate-600">Browse audio files from speaker metadata</p>
      </div>
    </div>

    {#if files.length === 0}
      <div class="empty-state">
        <svg class="empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <h3 class="text-xl font-semibold text-slate-700 mb-2">No Files Found</h3>
        <p class="text-slate-500 mb-6">Upload speaker metadata to see files</p>
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
            placeholder="Search files..."
            class="search-input"
          />
        </div>

        <div class="stats-card">
          <div class="stat">
            <div class="stat-label">Showing</div>
            <div class="stat-value">{filteredAndSortedFiles.length} / {files.length}</div>
          </div>
        </div>
      </div>

      <!-- Table -->
      <div class="table-container">
        <div class="overflow-x-auto">
          <table class="data-table">
            <thead>
              <tr>
                <th onclick={toggleSort} class="sortable">
                  <div class="th-content">
                    <span>Filename</span>
                    <svg class="sort-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      {#if sortDirection === 'asc'}
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                      {:else}
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      {/if}
                    </svg>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              {#each filteredAndSortedFiles as file, idx}
                <tr class:even-row={idx % 2 === 1}>
                  <td>
                    <a href="/swb/files/{encodeURIComponent(file.filename)}" class="filename-link">
                      {file.filename}
                    </a>
                  </td>
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
