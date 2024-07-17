/*
** mlx_int.h for mlx in 
** 
** Made by Charlie Root
** Login   <ol@epitech.net>
** 
** Started on  Mon Jul 31 16:45:48 2000 Charlie Root
** Last update Wed May 25 16:44:16 2011 Olivier Crouzet
*/



/*
** Internal settings for MiniLibX
*/

#ifndef MLX_INT_H

# define MLX_INT_H

# include <stdlib.h>
# include <stdio.h>
# include <string.h>
# include <unistd.h>
# include <fcntl.h>
# include <sys/mman.h>
# include <X11/Xlib.h>
# include <X11/Xutil.h>
# include <sys/ipc.h>
# include <sys/shm.h>
# include <X11/extensions/XShm.h>
# include <X11/XKBlib.h>
/* #include	<X11/xpm.h> */


# define MLX_TYPE_SHM_PIXMAP 3
# define MLX_TYPE_SHM 2
# define MLX_TYPE_XIMAGE 1

# define MLX_MAX_EVENT LASTEvent


# define ENV_DISPLAY "DISPLAY"
# define LOCALHOST "localhost"
# define ERR_NO_TRUECOLOR "MinilibX Error : No TrueColor Visual available.\n"
# define WARN_SHM_ATTACH "MinilibX Warning : X server can't attach shared memory.\n"


typedef	struct	s_xpm_col
{
	int		name;
	int		col;
}				t_xpm_col;


struct	s_col_name
{
	char	*name;
	int		color;
};

typedef struct	s_event_list
{
	int		mask;
	int		(*hook)();
	void	*param;
}				t_event_list;


typedef struct	s_win_list
{
	Window				window;
	GC					gc;
	struct s_win_list	*next;
	int					(*mouse_hook)();
	int					(*key_hook)();
	int					(*expose_hook)();
	void				*mouse_param;
	void				*key_param;
	void				*expose_param;
	t_event_list		hooks[MLX_MAX_EVENT];
}				t_win_list;


typedef struct	s_img
{
	XImage			*image;
	Pixmap			pix;
	GC				gc;
	int				size_line;
	int				bpp;
	int				width;
	int				height;
	int				type;
	int				format;
	char			*data;
	XShmSegmentInfo	shm;
}				t_img;

typedef struct	s_xvar
{
	Display		*display;
	Window		root;
	int			screen;
	int			depth;
	Visual		*visual;
	Colormap	cmap;
	int			private_cmap;
	t_win_list	*win_list;
	int			(*loop_hook)();
	void		*loop_param;
	int			use_xshm;
	int			pshm_format;
	int			do_flush;
	int			decrgb[6];
	Atom		wm_delete_window;
	Atom		wm_protocols;
	int 		end_loop;
}				t_xvar;


int				mlx_int_do_nothing();
int				mlx_get_color_value();
int				mlx_int_get_good_color();
int				mlx_int_find_in_pcm();
int				mlx_int_anti_resize_win();
int				mlx_int_wait_first_expose();
int				mlx_int_rgb_conversion();
int				mlx_int_deal_shm();
void			*mlx_int_new_xshm_image();
char			**mlx_int_str_to_wordtab();
void			*mlx_new_image();
int				shm_att_pb();
int				mlx_int_get_visual(t_xvar *xvar);
int				mlx_int_set_win_event_mask(t_xvar *xvar);
int				mlx_int_str_str_cote(char *str,char *find,int len);
int				mlx_int_str_str(char *str,char *find,int len);

int wrap_mlx_get_screen_size(void *mlx_ptr, int *size_x, int *size_y);
int wrap_mlx_mouse_show(void *mlx_ptr, void *win_ptr);
int wrap_mlx_mouse_hide(void *mlx_ptr, void *win_ptr);
int wrap_mlx_mouse_move(void *mlx_ptr, void *win_ptr, int x, int y);
int wrap_mlx_mouse_get_pos(void *mlx_ptr, void *win_ptr, int *x, int *y);
int wrap_mlx_do_sync(void *mlx_ptr);
int wrap_mlx_do_key_autorepeaton(void *mlx_ptr);
int wrap_mlx_do_key_autorepeatoff(void *mlx_ptr);
int wrap_mlx_hook_2(void *win_ptr, int x_event, int x_mask, int (*function_pointer)(int keycode, void *param), void *param);
int wrap_mlx_hook_1(void *win_ptr, int x_event, int x_mask, int (*function_pointer)(void *param), void *param);
int wrap_mlx_destroy_display(void *mlx_ptr);
int wrap_mlx_destroy_image(void *mlx_ptr, void *img_ptr);
int wrap_mlx_destroy_window(void *mlx_ptr, void *win_ptr);
void *wrap_mlx_xpm_file_to_image(void *mlx_ptr, char *filename, int *width, int *height);
void *wrap_mlx_xpm_to_image(void *mlx_ptr, char **xpm_data, int *width, int *height);
void wrap_mlx_set_font(void *mlx_ptr, void *win_ptr, char *name);

int wrap_mlx_string_put(void *mlx_ptr, void *win_ptr, int x, int y, int color, char *string);
int wrap_mlx_loop_end(void *mlx_ptr);
int wrap_mlx_loop(void *mlx_ptr);
int wrap_mlx_loop_hook_1(void *win_ptr, int (*function_ptr)(void *arg), void *param);
int wrap_mlx_loop_hook_2(void *win_ptr, int (*function_ptr)(int loopcode, void *arg), void *param);
int wrap_mlx_expose_hook_1(void *win_ptr, int (*function_ptr)(void *arg), void *param);
int wrap_mlx_expose_hook_2(void *win_ptr, int (*function_ptr)(int exposecode, void *arg), void *param);
int wrap_mlx_key_hook_1(void *win_ptr, int (*function_ptr)(void *arg), void *param);
int wrap_mlx_key_hook_2(void *win_ptr, int (*function_ptr)(int keycode, void *arg), void *param);
int wrap_mlx_mouse_hook_1(void *win_ptr, int (*function_ptr)(void *arg), void *param);
int wrap_mlx_mouse_hook_2(void *win_ptr, int (*function_ptr)(int keycode, void *arg), void *param);
int wrap_mlx_get_color_value(void *mlx_ptr, int color);
int wrap_mlx_put_image_to_window(void *mlx_ptr, void *win_ptr, void *img_ptr, int x, int y);
char *wrap_mlx_get_data_addr(void *img_ptr, int *bits_per_pixel, int *size_line, int *endian);

int   wrap_mlx_pixel_put(void *mlx_ptr, void *win_ptr, int x, int y, int color);
int   wrap_mlx_clear_window(void *mlx_ptr, void *win_ptr);
void *wrap_mlx_new_window(void *mlx_ptr, int size_x, int size_y, char *title);
void *wrap_mlx_init(void);
void *wrap_mlx_new_image(void *mlx_ptr, int width, int height);


#endif
