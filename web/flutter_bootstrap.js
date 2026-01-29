{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // Hide loading screen when app starts
    document.getElementById('loading').style.display = 'none';
    
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
