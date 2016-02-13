  namespace Synapse
  {
  // There are two basic plugin interfaces - ItemProvider and ActionProvider
  //
  // Plugins implementing ItemProvider have the ability to add items as a result for particular search query.
  // ActionProvider plugins on the other hand define actions that can be performed on items returned
  // by other ItemProviders ie. a "Home directory" is an item that gets added by a particular ItemProvider plugin
  // as a possible match when user searches for "home". ActionProvider will inspect this item, see that it's a file URI,
  // and will add an action for the item, for example "Open".
  //
  // Please note that for example a "Pause" action (for a music player), is still implemented by an ItemProvider and
  // it gets matched to the default "Run" action.
  //
  // Also note that a plugin can implement both of these interfaces if it's necessary.
  public class SpotifyPlugin : Object, Activatable, ItemProvider
  {
    // a mandatory property
    public bool enabled { get; set; default = true; }
 
    // this method is called when a plugin is enabled
    // use it to initialize your plugin
    public void activate ()
    {
    }
 
    // this method is called when a plugin is disabled
    // use it to free the resources you're using
    public void deactivate ()
    {
    }
 
    // register your plugin in the UI
    static void register_plugin ()
    {
		PluginRegistry.get_default ().register_plugin (
        typeof (SpotifyPlugin),
        _ ("SpotifyPlugin"), // plugin title
        _ ("An example plugin."), // description
        "system-run", // icon name
        register_plugin, // reference to this function
        Environment.find_program_in_path ("ls") != null, // true if user's system has all required components which the plugin needs
        _ ("ls is not installed") // error message
      );
    }
 
    static construct
    {
      // register the plugin when the class is constructed
      register_plugin ();
    }
 
    // an optional method to improve the speed of searches, 
    // if you return false here, the search method won't be called
    // for this query
    public bool handles_query (Query query)
    {
      // we will only search in the "Actions" category (that includes "All" as well)
      return (QueryFlags.ACTIONS in query.query_type);
    }
 
    public async ResultSet? search (Query query) throws SearchError
    {
      if (query.query_string.has_prefix ("spot"))
      {
        // if the user searches for "hello" + anything, we'll add our result
        var results = new ResultSet ();
        results.add (new SpotifyMatch (), MatchScore.AVERAGE);

        // make sure this method is called before returning any results
        query.check_cancellable ();
        return results;
      }

      // make sure this method is called before returning any results
      query.check_cancellable ();
      return null;
    }
 
    // define our Match object
    private class SpotifyMatch : UnknownMatch
    {
      public SpotifyMatch ()
      {
        Object (title: "SpotifyPlugin",
                description: "Result from SpotifyPlugin, hej simon",
                has_thumbnail: false, icon_name: "system-run");
      }
    }
  }
}
