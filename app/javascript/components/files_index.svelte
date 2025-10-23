<script>
    import { getp } from '../lib/ldcjs/getp';
    import Files from './files.svelte';
    let p = getp(window.location);
    // p.then(x => console.log(x));
</script>

{#await p}
    loading...
{:then v}
 
    <!-- {#if v.authenticated}
        <div class="Header flex justify-start bg-white fixed top-0 left-0 right-0 opacity-90 z-10">
            <Header user={v.user} kitid={v.kitid} kituid={v.kituid} locked={v.locked} />
        </div>
    {/if} -->

    <Files {...v} />

{/await}
