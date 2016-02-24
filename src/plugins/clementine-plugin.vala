/*
 * Copyright (C) 2012 Jörn Magens <shuerhaaken@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Authored by Jörn Magens <shuerhaaken@googlemail.com>
 * Authored by Andrea Brancaleoni <miwaxe@gmail.com>
 *
 */

namespace Synapse
{
  [DBus (name = "org.mpris.MediaPlayer2.Player")]
  private interface ClementinePlayer : Object
  {
    public const string UNIQUE_NAME = "org.mpris.MediaPlayer2.clementine";
    public const string OBJECT_PATH = "/org/mpris/MediaPlayer2";
    
    public abstract void next ()              throws IOError;
    public abstract void previous ()          throws IOError;
    public abstract void pause ()             throws IOError;
    public abstract void play_pause ()     throws IOError;
    public abstract void stop ()              throws IOError;
    public abstract void play ()              throws IOError;
    public abstract void open_uri (string uri) throws IOError;
  }

  [DBus (name = "org.mpris.MediaPlayer2")]
  private interface ClementineEngine : Object
  {
    public const string UNIQUE_NAME = "org.mpris.MediaPlayer2.clementine";
    public const string OBJECT_PATH = "/org/mpris/MediaPlayer2";
    
    public abstract void quit ()              throws IOError;
    public abstract void raise ()             throws IOError;
  }
  
  public class ClementineActions: Object, Activatable, ItemProvider, ActionProvider
  {
    public bool enabled { get; set; default = true; }
    
    public void activate ()
    {
    }
    
    public void deactivate ()
    {
    }
    
    static void register_plugin ()
    {
      DataSink.PluginRegistry.get_default ().register_plugin (
        typeof (ClementineActions),
        "Clementine",
        _ ("Control Clementine media player."),
        "clementine",
        register_plugin,
        Environment.find_program_in_path ("clementine") != null,
        _ ("Clementine is not installed!")
      );
    }
    
    static construct
    {
      register_plugin ();
    }
    
    private abstract class ClementineAction: Object, Match
    {
      // from Match interface
      public string title          { get; construct set; }
      public string description    { get; set; }
      public string icon_name      { get; construct set; }
      public bool has_thumbnail    { get; construct set; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type  { get; construct set; }
      public int default_relevancy { get; set; }
      
      public abstract bool valid_for_match (Match match);
      public abstract void execute_internal (Match? match);
      
      public void execute (Match? match)
      {
        execute_internal (match);
      }
      
      public virtual int get_relevancy ()
      {
        bool clementine_running = DBusService.get_default ().name_has_owner (
          ClementinePlayer.UNIQUE_NAME);
        return clementine_running ? default_relevancy + Match.Score.INCREMENT_LARGE : default_relevancy;
      }
    }
    
    private abstract class ClementineControlMatch: Object, Match
    {
      // for Match interface
      public string title           { get; construct set; }
      public string description     { get; set; default = ""; }
      public string icon_name       { get; construct set; default = ""; }
      public bool has_thumbnail     { get; construct set; default = false; }
      public string thumbnail_path  { get; construct set; }
      public MatchType match_type   { get; construct set; }
      
      public void execute (Match? match)
      {
        this.do_action ();
      }
      
      public abstract void do_action ();
      
      public virtual bool action_available ()
      {
        return DBusService.get_default ().name_has_owner (
          ClementinePlayer.UNIQUE_NAME
        );
      }
    }
    
    /* MATCHES of Type.ACTION */
    private class Quit : ClementineControlMatch
    {
      public Quit ()
      {
        Object (title:         _ ("Quit"),
                description:   _ ("Quit Clementine"),
                icon_name:     "gtk-close",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementineEngine player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementineEngine.UNIQUE_NAME,
                                           ClementineEngine.OBJECT_PATH);
          player.quit ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }

    private class Raise : ClementineControlMatch
    {
      public Raise ()
      {
        Object (title:         _ ("Raise"),
                description:   _ ("Show Clementine"),
                icon_name:     "clementine",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementineEngine player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementineEngine.UNIQUE_NAME,
                                           ClementineEngine.OBJECT_PATH);
          player.raise ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }

    private class Play : ClementineControlMatch
    {
      public Play ()
      {
        Object (title:         _ ("Play"),
                description:   _ ("Start playback in Clementine"),
                icon_name:     "media-playback-start", 
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.play ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }

    private class TogglePlaying : ClementineControlMatch
    {
      public TogglePlaying ()
      {
        Object (title:         _ ("TogglePlaying"),
                description:   _ ("Start/Pause playback in Clementine"),
                icon_name:     "media-playback-pause", 
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.play_pause ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }

      public override bool action_available ()
      {
        return true;
      }
    }
    
    private class Pause : ClementineControlMatch
    {
      public Pause ()
      {
        Object (title:         _ ("Pause"),
                description:   _ ("Pause playback in Clementine"),
                icon_name:     "media-playback-pause",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.pause ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }
    
    private class Next : ClementineControlMatch
    {
      public Next ()
      {
        Object (title:         _ ("Next"),
                description:   _ ("Plays the next song in Clementine's playlist"),
                icon_name:     "media-skip-forward",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          
          player.next ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }
    
    private class Previous : ClementineControlMatch
    {
      public Previous ()
      {
        Object (title:         _ ("Previous"),
                description:   _ ("Plays the previous song in Clementine's playlist"),
                icon_name:     "media-skip-backward",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.previous ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }
    
    private class Stop : ClementineControlMatch
    {
      public Stop ()
      {
        Object (title:         _ ("Stop"),
                description:   _ ("Stops the playback of Clementine"),
                icon_name:     "media-playback-stop",
                has_thumbnail: false,
                match_type:    MatchType.ACTION
                );
      }
      
      public override void do_action ()
      {
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.stop ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
    }
    
    /* ACTIONS FOR MP3s */
    private class OpenUri: ClementineAction
    {
      public OpenUri ()
      {
        Object (title: _ ("Play in Clementine"),
                description: _ ("Queues and plays the song"),
                icon_name: "media-playback-start",
                has_thumbnail: false,
                match_type: MatchType.ACTION,
                default_relevancy: Match.Score.ABOVE_AVERAGE
                );
      }
      
      public override void execute_internal (Match? match)
      {
        return_if_fail (match.match_type == MatchType.GENERIC_URI);
        UriMatch uri = match as UriMatch;
        return_if_fail ((uri.file_type & QueryFlags.AUDIO) != 0 ||
                        (uri.file_type & QueryFlags.VIDEO) != 0);
        try {
          ClementinePlayer player = Bus.get_proxy_sync (BusType.SESSION,
                                           ClementinePlayer.UNIQUE_NAME,
                                           ClementinePlayer.OBJECT_PATH);
          player.open_uri (uri.uri);
          player.play ();
        } catch (IOError e) {
          Utils.Logger.warning (this, "Clementine is not available.\n%s", e.message);
        }
      }
      
      public override bool valid_for_match (Match match)
      {
        switch (match.match_type)
        {
          case MatchType.GENERIC_URI:
            UriMatch uri = match as UriMatch;
            if ((uri.file_type & QueryFlags.AUDIO) != 0 ||
                (uri.file_type & QueryFlags.VIDEO) != 0)
              return true;
            else
              return false;
          default:
            return false;
        }
      }
    }
    
    private Gee.List<ClementineAction> actions;
    private Gee.List<ClementineControlMatch> matches;
    
    construct
    {
      actions = new Gee.ArrayList<ClementineAction> ();
      matches = new Gee.ArrayList<ClementineControlMatch> ();
      
      actions.add (new OpenUri());
      
      matches.add (new Raise ());
      matches.add (new Quit ());
      
      matches.add (new Play ());
      matches.add (new TogglePlaying ());
      matches.add (new Pause ());
      matches.add (new Stop ());
      matches.add (new Previous ());
      matches.add (new Next ());
    }
    
    public async ResultSet? search (Query q) throws SearchError
    {
      // we only search for actions
      if (!(QueryFlags.ACTIONS in q.query_type)) return null;
      
      var result = new ResultSet ();
      
      var matchers = Query.get_matchers_for_query (q.query_string, 0,
        RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);
      
      foreach (var action in matches)
      {
        if (!action.action_available ()) continue;
        foreach (var matcher in matchers)
        {
          if (matcher.key.match (action.title))
          {
            result.add (action, matcher.value - Match.Score.INCREMENT_SMALL);
            break;
          }
        }
      }
      q.check_cancellable ();
      return result;
    }

    public ResultSet? find_for_match (ref Query query, Match match)
    {
      bool query_empty = query.query_string == "";
      var results = new ResultSet ();
      
      if (query_empty)
      {
        foreach (var action in actions)
        {
          if (action.valid_for_match (match))
          {
            results.add (action, action.get_relevancy ());
          }
        }
      }
      else
      {
        var matchers = Query.get_matchers_for_query (query.query_string, 0,
          RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);
        foreach (var action in actions)
        {
          if (!action.valid_for_match (match)) continue;
          foreach (var matcher in matchers)
          {
            if (matcher.key.match (action.title))
            {
              results.add (action, matcher.value);
              break;
            }
          }
        }
      }
      return results;
    }
  }
}
