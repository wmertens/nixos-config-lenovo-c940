// The Synaptics touchpad firmware sometimes restarts by itself and comes back in
// mouse mode (no multitouch). Linux doesn't notice, but motion on its "Mouse" input
// node gives it away: re-send Input Mode = touchpad, and rebind the driver (what
// reset-trackpad does) if mouse reports keep coming.
#include <fcntl.h>
#include <glob.h>
#include <limits.h>
#include <linux/hidraw.h>
#include <linux/input.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define DEV "i2c-SYNA2BA6:00"
#define SYS "/sys/bus/i2c/devices/" DEV
#define DRV "/sys/bus/i2c/drivers/i2c_hid_acpi"
#define NAME "SYNA2BA6:00 06CB:CF00 Mouse\n"
// Mouse reports later than this after Input Mode mean it didn't take
#define GRACE 2
// Mouse reports later than this after Input Mode are a new failure, not the same one
#define EPISODE 60

static double now(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec + ts.tv_nsec / 1e9;
}

static int write_file(const char *path, const char *s) {
	int fd = open(path, O_WRONLY), r = -1;
	if (fd >= 0) {
		r = write(fd, s, strlen(s));
		close(fd);
	}
	return r;
}

// Fills /dev paths of the Mouse event node and the hidraw node; 0 if not (yet) there
static int find(char *event, char *hidraw) {
	glob_t g;
	int found = 0;
	if (glob(SYS "/*/hidraw/hidraw*", 0, NULL, &g) == 0) {
		snprintf(hidraw, PATH_MAX, "/dev/%s", strrchr(g.gl_pathv[0], '/') + 1);
		found = 1;
	}
	globfree(&g);
	if (!found || glob(SYS "/*/input/input*/event*", 0, NULL, &g) != 0)
		return 0;
	found = 0;
	for (size_t i = 0; i < g.gl_pathc && !found; i++) {
		char path[PATH_MAX], name[128] = "";
		snprintf(path, sizeof path, "%s/../name", g.gl_pathv[i]);
		FILE *f = fopen(path, "r");
		if (f) {
			if (!fgets(name, sizeof name, f))
				name[0] = 0;
			fclose(f);
		}
		if (strcmp(name, NAME) == 0) {
			snprintf(event, PATH_MAX, "/dev/input/%s", strrchr(g.gl_pathv[i], '/') + 1);
			found = 1;
		}
	}
	globfree(&g);
	return found;
}

static int set_touchpad_mode(const char *hidraw) {
	// Feature report 4 is Input Mode, 3 = touchpad (from the report descriptor)
	unsigned char buf[] = {4, 3};
	int fd = open(hidraw, O_RDWR), r = -1;
	if (fd >= 0) {
		r = ioctl(fd, HIDIOCSFEATURE(sizeof buf), buf);
		close(fd);
	}
	return r;
}

static void watch(const char *event, const char *hidraw) {
	int fd = open(event, O_RDONLY);
	if (fd < 0) {
		perror(event);
		return;
	}
	struct input_event ev[64];
	double fixed_at = -EPISODE;
	ssize_t n;
	while ((n = read(fd, ev, sizeof ev)) > 0) {
		int rel = 0;
		for (size_t i = 0; i < n / sizeof *ev; i++)
			rel |= ev[i].type == EV_REL;
		if (!rel)
			continue;
		double since = now() - fixed_at;
		if (since > EPISODE) {
			puts("touchpad in mouse mode, re-sending Input Mode");
			if (set_touchpad_mode(hidraw) >= 0) {
				fixed_at = now();
				continue;
			}
			perror("Input Mode failed");
		} else if (since < GRACE) {
			continue;
		}
		puts("still in mouse mode, rebinding");
		if (write_file(DRV "/unbind", DEV) < 0 || write_file(DRV "/bind", DEV) < 0)
			perror("rebind");
		break;
	}
	// The device goes away on rebind; the caller picks up the new nodes
	if (n < 0)
		perror(event);
	close(fd);
}

int main(void) {
	setvbuf(stdout, NULL, _IOLBF, 0);
	char event[PATH_MAX], hidraw[PATH_MAX];
	for (;;) {
		if (find(event, hidraw)) {
			printf("watching %s %s\n", event, hidraw);
			watch(event, hidraw);
		}
		sleep(1);
	}
}
