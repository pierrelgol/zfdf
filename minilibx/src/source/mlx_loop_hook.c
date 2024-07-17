/*
** mlx_loop_hook.c for MiniLibX in 
** 
** Made by Charlie Root
** Login   <ol@epitech.net>
** 
** Started on  Thu Aug  3 11:49:06 2000 Charlie Root
** Last update Fri Feb 23 17:11:39 2001 Charlie Root
*/


#include	"mlx_int.h"




int	mlx_loop_hook(t_xvar *xvar,int (*funct)(),void *param)
{
  xvar->loop_hook = funct;
  xvar->loop_param = param;
}

int wrap_mlx_loop_hook_2(void *win_ptr, int (*function_ptr)(int loopcode, void *arg), void *param)
{
	return mlx_loop_hook(win_ptr, function_ptr, param);
}

int wrap_mlx_loop_hook_1(void *win_ptr, int (*function_ptr)(void *arg), void *param)
{
	return mlx_loop_hook(win_ptr, function_ptr, param);
}
