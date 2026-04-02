extends Node



signal item_entered_viewport(item : Item)
signal item_exited_viewport(item : Item)
signal bird_created(bird : Bird)

signal settings_changed()

@warning_ignore("unused_signal")
signal save_slot_set(slot : int)
@warning_ignore("unused_signal")
signal new_game_started()
@warning_ignore("unused_signal")
@warning_ignore("unused_signal")
signal before_screenshot()
@warning_ignore("unused_signal")
signal screenshot_taken()
@warning_ignore("unused_signal")
signal screen_changed(old_screen : String, new_screen : String)
