#include "AccuBuffer.h"
#include <math.h>

#define PI_ 3.14159265358979323846

void AccuBuffer::accFrustum(GLdouble left, GLdouble right, GLdouble bottom,
	GLdouble top, GLdouble near, GLdouble far, GLdouble pixdx, 
	GLdouble pixdy, GLdouble eyedx, GLdouble eyedy, 
	GLdouble focus)
{
	GLdouble xwsize, ywsize; 
	GLdouble dx, dy;
	GLint viewport[4];

	glGetIntegerv (GL_VIEWPORT, viewport);

	xwsize = right - left;
	ywsize = top - bottom;
	dx = -(pixdx*xwsize/(GLdouble) viewport[2] + 
		eyedx*near/focus);
	dy = -(pixdy*ywsize/(GLdouble) viewport[3] + 
		eyedy*near/focus);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum (left + dx, right + dx, bottom + dy, top + dy, 
		near, far);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef (-eyedx, -eyedy, 0.0);
}

void AccuBuffer::accPerspective(GLdouble fovy, GLdouble aspect, 
	GLdouble near, GLdouble far, GLdouble pixdx, GLdouble pixdy, 
	GLdouble eyedx, GLdouble eyedy, GLdouble focus)
{
	GLdouble fov2,left,right,bottom,top;
	fov2 = ((fovy*PI_) / 180.0) / 2.0;

	top = near / (cos(fov2) / sin(fov2));
	bottom = -top;
	right = top * aspect;
	left = -right;

	accFrustum (left, right, bottom, top, near, far,
		pixdx, pixdy, eyedx, eyedy, focus);
}

void AccuBuffer::gluLookAt( GLdouble eyex, GLdouble eyey, GLdouble eyez, 
	GLdouble centerx, GLdouble centery, GLdouble centerz, 
	GLdouble upx, GLdouble upy, GLdouble upz )
{
	GLdouble m[16]; 
   GLdouble x[3], y[3], z[3]; 
   GLdouble mag; 
   /* Make rotation matrix */ 
   /* Z vector */ 
   z[0] = eyex - centerx; 
   z[1] = eyey - centery; 
   z[2] = eyez - centerz; 
   mag = sqrt( z[0]*z[0] + z[1]*z[1] + z[2]*z[2] ); 
   if (mag) {  /* mpichler, 19950515 */ 
      z[0] /= mag; 
      z[1] /= mag; 
      z[2] /= mag; 
   } 
   /* Y vector */ 
   y[0] = upx; 
   y[1] = upy; 
   y[2] = upz; 
   /* X vector = Y cross Z */ 
   x[0] =  y[1]*z[2] - y[2]*z[1]; 
   x[1] = -y[0]*z[2] + y[2]*z[0]; 
   x[2] =  y[0]*z[1] - y[1]*z[0]; 
   /* Recompute Y = Z cross X */ 
   y[0] =  z[1]*x[2] - z[2]*x[1]; 
   y[1] = -z[0]*x[2] + z[2]*x[0]; 
   y[2] =  z[0]*x[1] - z[1]*x[0]; 
   /* mpichler, 19950515 */ 
   /* cross product gives area of parallelogram, which is < 1.0 for 
    * non-perpendicular unit-length vectors; so normalize x, y here 
    */ 
   mag = sqrt( x[0]*x[0] + x[1]*x[1] + x[2]*x[2] ); 
   if (mag) { 
      x[0] /= mag; 
      x[1] /= mag; 
      x[2] /= mag; 
   } 
   mag = sqrt( y[0]*y[0] + y[1]*y[1] + y[2]*y[2] ); 
   if (mag) { 
      y[0] /= mag; 
      y[1] /= mag; 
      y[2] /= mag; 
   } 
#define M(row,col)  m[col*4+row] 
   M(0,0) = x[0];  M(0,1) = x[1];  M(0,2) = x[2];  M(0,3) = 0.0; 
   M(1,0) = y[0];  M(1,1) = y[1];  M(1,2) = y[2];  M(1,3) = 0.0; 
   M(2,0) = z[0];  M(2,1) = z[1];  M(2,2) = z[2];  M(2,3) = 0.0; 
   M(3,0) = 0.0;   M(3,1) = 0.0;   M(3,2) = 0.0;   M(3,3) = 1.0; 
#undef M 
   glMultMatrixd( m ); 
   /* Translate Eye to Origin */ 
   glTranslated( -eyex, -eyey, -eyez ); 
}