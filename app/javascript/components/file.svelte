<script>

  import { getp } from '../lib/ldcjs/getp';
  let { filename, speakers = [], segments = [] } = $props()
  let url = $state();
  getp(`/switchboard?filename=${encodeURIComponent(filename)}`).then(x => url = x);

  let audioElement
  let canvasElement
  let currentTime = $state(0)
  let duration = $state(0)
  let isPlaying = $state(false)
  let waveformData = $state([])
  let audioContext
  let analyser
  let selectedSegment = $state(null) // { beg, end } - highlighted segment
  let playingSegment = $state(null) // { beg, end } - segment being played

  function selectSegment(beg, end) {
    selectedSegment = { beg, end }
    playingSegment = null
    if (!isPlaying) {
      // Position to start of segment but don't play
      audioElement.currentTime = beg
    }
    drawWaveform()
  }

  function togglePlay() {
    if (!audioElement) return

    if (isPlaying) {
      audioElement.pause()
    } else {
      if (selectedSegment) {
        // Play the selected segment
        playingSegment = selectedSegment
        audioElement.currentTime = selectedSegment.beg
        audioElement.play()

        // Stop at segment end
        const checkTime = () => {
          if (audioElement.currentTime >= playingSegment.end) {
            audioElement.pause()
            playingSegment = null
          } else if (playingSegment) {
            requestAnimationFrame(checkTime)
          }
        }
        requestAnimationFrame(checkTime)
      } else {
        // Play full file
        audioElement.play()
      }
    }
  }

  function handleTimeUpdate() {
    if (audioElement) {
      currentTime = audioElement.currentTime
    }
  }

  async function handleLoadedMetadata() {
    if (audioElement) {
      duration = audioElement.duration
      await generateWaveform()
    }
  }

  function handlePlay() {
    isPlaying = true
    if (!audioContext) {
      setupAudioContext()
    }
    drawWaveform()
  }

  function handlePause() {
    isPlaying = false
  }

  function formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00'
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  function seekTo(event) {
    if (!audioElement) return
    const rect = event.currentTarget.getBoundingClientRect()
    const x = event.clientX - rect.left
    const percentage = x / rect.width

    // Always seek within full file on waveform
    audioElement.currentTime = percentage * duration
  }

  function setupAudioContext() {
    if (audioContext) return

    audioContext = new (window.AudioContext || window.webkitAudioContext)()
    analyser = audioContext.createAnalyser()
    analyser.fftSize = 2048

    const source = audioContext.createMediaElementSource(audioElement)
    source.connect(analyser)
    analyser.connect(audioContext.destination)
  }

  async function generateWaveform() {
    try {
      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer()

      const tempContext = new (window.AudioContext || window.webkitAudioContext)()
      const audioBuffer = await tempContext.decodeAudioData(arrayBuffer)

      const rawData = audioBuffer.getChannelData(0)
      const samples = 1000 // Number of samples for waveform visualization
      const blockSize = Math.floor(rawData.length / samples)
      const filteredData = []

      for (let i = 0; i < samples; i++) {
        let blockStart = blockSize * i
        let sum = 0
        for (let j = 0; j < blockSize; j++) {
          sum += Math.abs(rawData[blockStart + j])
        }
        filteredData.push(sum / blockSize)
      }

      waveformData = filteredData
      drawWaveform()
    } catch (error) {
      console.error('Error generating waveform:', error)
    }
  }

  function drawWaveform() {
    if (!canvasElement || waveformData.length === 0) return

    const ctx = canvasElement.getContext('2d')
    const width = canvasElement.width
    const height = canvasElement.height

    ctx.clearRect(0, 0, width, height)

    // Always show full file view
    const progressPosition = duration > 0 ? (currentTime / duration) * width : 0
    const barWidth = width / waveformData.length
    const maxAmplitude = Math.max(...waveformData)

    waveformData.forEach((amplitude, i) => {
      const barHeight = (amplitude / maxAmplitude) * (height / 2)
      const x = i * barWidth
      const y = height / 2

      // Determine if this bar is within the selected segment
      const timePosition = (i / waveformData.length) * duration
      let isInSegment = false
      if (selectedSegment) {
        isInSegment = timePosition >= selectedSegment.beg && timePosition <= selectedSegment.end
      }

      // Color based on state
      if (isInSegment) {
        // In selected segment
        if (x < progressPosition) {
          ctx.fillStyle = '#2563eb' // Blue - played part of segment
        } else {
          ctx.fillStyle = '#60a5fa' // Light blue - unplayed part of segment
        }
      } else {
        // Not in segment
        if (x < progressPosition) {
          ctx.fillStyle = '#94a3b8' // Gray blue - played
        } else {
          ctx.fillStyle = '#cbd5e1' // Light gray - unplayed
        }
      }

      ctx.fillRect(x, y - barHeight, barWidth - 1, barHeight * 2)
    })

    // Draw segment boundaries if segment is selected
    if (selectedSegment) {
      const segmentStart = (selectedSegment.beg / duration) * width
      const segmentEnd = (selectedSegment.end / duration) * width

      ctx.fillStyle = '#10b981'
      ctx.fillRect(segmentStart - 1, 0, 2, height)
      ctx.fillRect(segmentEnd - 1, 0, 2, height)
    }

    // Draw playhead
    ctx.fillStyle = '#ef4444'
    ctx.fillRect(progressPosition - 1, 0, 2, height)

    if (isPlaying) {
      requestAnimationFrame(drawWaveform)
    }
  }

  $effect(() => {
    if (canvasElement && waveformData.length > 0) {
      drawWaveform()
    }
  })
</script>

<div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="mb-8">
      <a href="/swb/files" class="back-link">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Files
      </a>
    </div>

    <!-- Audio Player -->
    <div class="audio-player-card mb-8">
      <audio
        bind:this={audioElement}
        src="{url}"
        crossorigin="anonymous"
        ontimeupdate={handleTimeUpdate}
        onloadedmetadata={handleLoadedMetadata}
        onplay={handlePlay}
        onpause={handlePause}
      ></audio>

      <!-- Waveform Display -->
      <!-- svelte-ignore a11y_click_events_have_key_events -->
      <!-- svelte-ignore a11y_no_static_element_interactions -->
      <div class="waveform-container mb-4" onclick={seekTo}>
        <canvas
          bind:this={canvasElement}
          width="1200"
          height="120"
          class="waveform-canvas"
        ></canvas>
      </div>

      <div class="audio-controls">
        <button onclick={togglePlay} class="play-button">
          {#if isPlaying}
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
            </svg>
          {:else}
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z"/>
            </svg>
          {/if}
        </button>

        <div class="time-display">{formatTime(currentTime)}</div>

        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div class="progress-container" onclick={seekTo}>
          <div class="progress-bar">
            <div class="progress-fill" style="width: {duration > 0 ? (currentTime / duration * 100) : 0}%"></div>
          </div>
        </div>

        <div class="time-display">{formatTime(duration)}</div>
      </div>
    </div>

    <!-- Speakers Section -->
    {#if false && speakers.length > 0}
      <div class="section-card mb-8">
        <h2 class="section-title">Speaker Information</h2>
        <div class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Channel</th>
                <th>Sex</th>
                <th>Birth Year</th>
                <th>Dialect Area</th>
                <th>Education</th>
                <th>Topic Description</th>
              </tr>
            </thead>
            <tbody>
              {#each speakers as speaker, idx}
                <tr class:even-row={idx % 2 === 1}>
                  <td><span class="badge">{speaker.channel || '-'}</span></td>
                  <td><span class="badge badge-sex">{speaker.sex || '-'}</span></td>
                  <td>{speaker.birth_year || '-'}</td>
                  <td>{speaker.dialect_area || '-'}</td>
                  <td>{speaker.education || '-'}</td>
                  <td class="max-w-xs truncate">{speaker.topic_description || '-'}</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </div>
    {/if}

    <!-- Segments Section -->
    {#if segments.length > 0}
      <div class="section-card">
        <h2 class="section-title">Segments ({segments.length})</h2>
        <div class="table-container segments-table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Channel</th>
                <th>Begin</th>
                <th>End</th>
                <th>Turn</th>
                <th>Text</th>
              </tr>
            </thead>
            <tbody>
              {#each segments as segment, idx}
                <tr
                  class:even-row={idx % 2 === 1}
                  class:selected={selectedSegment && selectedSegment.beg === segment.beg && selectedSegment.end === segment.end}
                  class="segment-row"
                  onclick={() => selectSegment(segment.beg, segment.end)}
                >
                  <td><span class="badge">{segment.channel || '-'}</span></td>
                  <td>{segment.beg?.toFixed(2) || '-'}</td>
                  <td>{segment.end?.toFixed(2) || '-'}</td>
                  <td>{segment.turn || '-'}</td>
                  <td class="max-w-2xl">
                    <div class="segment-text">
                      <svg class="select-icon" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M9 5v14l11-7z"/>
                      </svg>
                      {segment.text || '-'}
                    </div>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </div>
    {/if}

    {#if speakers.length === 0 && segments.length === 0}
      <div class="empty-state">
        <svg class="empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
        <h3 class="text-xl font-semibold text-slate-700 mb-2">No Data Found</h3>
        <p class="text-slate-500">No speakers or segments associated with this file.</p>
      </div>
    {/if}
  </div>
</div>

<style>
  .back-link {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    color: #2563eb;
    font-weight: 500;
    text-decoration: none;
    transition: color 0.2s;
  }

  .back-link:hover {
    color: #1d4ed8;
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
    font-size: 2.5rem;
    font-weight: 700;
    color: #2563eb;
  }

  .section-card {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    padding: 1.5rem;
  }

  .section-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: #1e293b;
    margin-bottom: 1rem;
  }

  .table-container {
    overflow-x: auto;
    border-radius: 0.5rem;
    border: 1px solid #e2e8f0;
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
    padding: 0.75rem 1rem;
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
    padding: 0.75rem 1rem;
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

  .badge-sex {
    background: #f3e8ff;
    color: #6b21a8;
    border-color: #e9d5ff;
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

  .audio-player-card {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    padding: 1.5rem;
  }

  .audio-controls {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .play-button {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 3rem;
    height: 3rem;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 50%;
    cursor: pointer;
    transition: background 0.2s;
    flex-shrink: 0;
  }

  .play-button:hover {
    background: #1d4ed8;
  }

  .time-display {
    font-size: 0.875rem;
    font-weight: 500;
    color: #475569;
    min-width: 3rem;
    text-align: center;
  }

  .progress-container {
    flex: 1;
    cursor: pointer;
    padding: 0.5rem 0;
  }

  .progress-bar {
    height: 0.5rem;
    background: #e2e8f0;
    border-radius: 9999px;
    overflow: hidden;
  }

  .progress-fill {
    height: 100%;
    background: #2563eb;
    transition: width 0.1s linear;
  }

  .segment-row {
    cursor: pointer;
  }

  .segment-row:hover {
    background: #dbeafe !important;
  }

  .segment-row.selected {
    background: #bfdbfe !important;
    border-left: 3px solid #2563eb;
  }

  .segment-text {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .select-icon {
    width: 1rem;
    height: 1rem;
    color: #2563eb;
    flex-shrink: 0;
    opacity: 0;
    transition: opacity 0.2s;
  }

  .segment-row:hover .select-icon {
    opacity: 1;
  }

  .segment-row.selected .select-icon {
    opacity: 1;
  }

  .segments-table-container {
    max-height: 400px;
    overflow-y: auto;
  }

  .waveform-container {
    cursor: pointer;
    border-radius: 0.5rem;
    overflow: hidden;
    background: #f8fafc;
  }

  .waveform-canvas {
    width: 100%;
    height: auto;
    display: block;
  }
</style>
