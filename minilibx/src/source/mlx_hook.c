/*
** mlx_hook.c for MiniLibX in 
** 
** Made by Charlie Root
** Login   <ol@epitech.net>
** 
** Started on  Thu Aug  3 11:49:06 2000 Charlie Root
** Last update Fri Jan 28 17:05:28 2005 Olivier Crouzet
*/


#include	"mlx_int.h"




int	mlx_hook(t_win_list *win, int x_event, int x_mask, 
		 int (*funct)(),void *param)
{
  win->hooks[x_event].hook = funct;
  win->hooks[x_event].param = param;
  win->hooks[x_event].mask = x_mask;
}


int	mlx_do_key_autorepeatoff(t_xvar *xvar)
{
  XAutoRepeatOff(xvar->display);
}

int	mlx_do_key_autorepeaton(t_xvar *xvar)
{
  XAutoRepeatOn(xvar->display);
}


int	mlx_do_sync(t_xvar *xvar)
{
  XSync(xvar->display, False);
}

int wrap_mlx_hook_1(void *win_ptr, int x_event, int x_mask, int (*function_pointer)(void *param), void *param)
{
	return mlx_hook(win_ptr, x_event, x_mask, function_pointer, param);
}

int wrap_mlx_hook_2(void *win_ptr, int x_event, int x_mask, int (*function_pointer)(int keycode, void *param), void *param)
{
	return mlx_hook(win_ptr, x_event, x_mask, function_pointer, param);
}

int wrap_mlx_do_key_autorepeatoff(void *mlx_ptr)
{
	return mlx_do_key_autorepeatoff(mlx_ptr);
}

int wrap_mlx_do_key_autorepeaton(void *mlx_ptr)
{
	return mlx_do_key_autorepeaton(mlx_ptr);
}

int wrap_mlx_do_sync(void *mlx_ptr)
{
	return mlx_do_sync(mlx_ptr);
}
