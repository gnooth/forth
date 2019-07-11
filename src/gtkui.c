// Copyright (C) 2019 Peter Graves <gnooth@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <gtk/gtk.h>

static double char_width = 0.0;
static double char_height = 0.0;

static GtkWidget *window;

static gboolean
key_press_callback (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
  g_print ("key pressed 0x%08x 0x%08x %s\n", event->state, event->keyval,
           gdk_keyval_name (event->keyval));
  if (event->keyval == 0x71)
    {
      gtk_widget_destroy (window);
      gtk_main_quit ();
    }
  return TRUE;
}

extern void gtkui_textview_paint (void);

static gboolean
textview_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("textview_draw_callback called\n");

  gtkui_textview_paint ();

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);
  cairo_set_font_size (cr, 14.0);

  if (char_width == 0.0)
    {
      cairo_font_extents_t fe;
      cairo_font_extents (cr, &fe);
      g_print ("ascent = %f  descent = %f\n", fe.ascent, fe.descent);
      g_print ("height = %f\n", fe.height);
      g_print ("max_x_advance = %f max_y_advance = %f\n",
               fe.max_x_advance, fe.max_x_advance);

      cairo_text_extents_t extents;
      cairo_text_extents (cr, "test", &extents);
      char_width = extents.width / 4;
      char_height = extents.height;
      g_print ("textview char_width = %f char_height = %f\n",
               char_width, char_height);
    }

  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);
  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_move_to (cr, 0, 18);
  cairo_show_text (cr, "This is a test line 1");
  cairo_move_to (cr, 0, 36);
  cairo_show_text (cr, "This is a test line 2");
//   cairo_move_to (cr, 48, 0);
//   cairo_show_text (cr, "This is a test line 3");
  return TRUE;
}

static gboolean
modeline_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("modeline_draw_callback called\n");

  GtkAllocation allocation;
  gtk_widget_get_allocation (widget, &allocation);
  g_print ("modeline height = %d\n", allocation.height);

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_text_extents_t extents;
  cairo_text_extents (cr, "test", &extents);
  double char_width = extents.width / 4;
  double char_height = extents.height;
  g_print ("modeline char_width = %f char_height = %f\n", char_width, char_height);

  cairo_move_to (cr, 0, 14);
  cairo_set_font_size (cr, 14.0);
  // white background
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_paint (cr);
  // black text
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_show_text (cr, " feline-mode.feline 1:1 (396)");
  return TRUE;
}

static gboolean
minibuffer_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("minibuffer_draw_callback called\n");

  GtkAllocation allocation;
  gtk_widget_get_allocation (widget, &allocation);
  g_print ("minibuffer height = %d\n", allocation.height);

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_text_extents_t extents;
  cairo_text_extents (cr, "test", &extents);
  double char_width = extents.width / 4;
  double char_height = extents.height;
  g_print ("minibufffer char_width = %f char_height = %f\n", char_width, char_height);

  cairo_move_to (cr, 0, 14);
  cairo_set_font_size (cr, 14.0);
  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);
  // white text
//   cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
//   cairo_show_text (cr, "This is a test!");
  return TRUE;
}

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (window), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (window), 800, 600);

  GtkBox *box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_VERTICAL, 0));
  gtk_container_add (GTK_CONTAINER (window), GTK_WIDGET(box));

  GtkWidget *drawing_area_1 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_1, 800, 568);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_1);
  gtk_widget_set_can_focus (drawing_area_1, TRUE);

  gtk_widget_set_events (drawing_area_1,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         //                          GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (drawing_area_1, "draw",
                    G_CALLBACK (textview_draw_callback), NULL);
  g_signal_connect (drawing_area_1, "key-press-event",
                    G_CALLBACK(key_press_callback), NULL);

  GtkWidget *drawing_area_2 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_2, 568, 16);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_2);
  gtk_widget_set_can_focus (drawing_area_2, TRUE);

  gtk_widget_set_events (drawing_area_2,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         //                          GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (drawing_area_2, "draw",
                    G_CALLBACK (modeline_draw_callback), NULL);
//   g_signal_connect (drawing_area_2, "key-press-event",
//                     G_CALLBACK(key_press_callback), NULL);

  GtkWidget *drawing_area_3 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_3, 584, 16);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_3);
  gtk_widget_set_can_focus (drawing_area_3, TRUE);

  gtk_widget_set_events (drawing_area_3,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         //                          GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (drawing_area_3, "draw",
                    G_CALLBACK (minibuffer_draw_callback), NULL);
  //   g_signal_connect (drawing_area_3, "key-press-event",
  //                     G_CALLBACK(key_press_callback), NULL);

//   gtk_container_add (GTK_CONTAINER (box), drawing_area_1);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_2);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_3);
  gtk_box_pack_end (box, drawing_area_3, FALSE, FALSE, 0);
  gtk_box_pack_end (box, drawing_area_2, FALSE, FALSE, 0);
  gtk_box_pack_end (box, drawing_area_1, FALSE, FALSE, 0);

  gtk_widget_show_all (window);
  g_print ("leaving gtkui__initialize\n");
  gtk_main ();
}