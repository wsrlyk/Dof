#ifndef _ACCUBUFFER_H_
#define _ACCUBUFFER_H_

#include <GL/glew.h>

class AccuBuffer
{
public:
	static void accFrustum(GLdouble left, GLdouble right, GLdouble bottom,
		GLdouble top, GLdouble near, GLdouble far, GLdouble pixdx, 
		GLdouble pixdy, GLdouble eyedx, GLdouble eyedy, 
		GLdouble focus);
	static void accPerspective(GLdouble fovy, GLdouble aspect, 
		GLdouble near, GLdouble far, GLdouble pixdx, GLdouble pixdy, 
		GLdouble eyedx, GLdouble eyedy, GLdouble focus);
	static void gluLookAt( GLdouble eyex, GLdouble eyey, GLdouble eyez, 
		GLdouble centerx, GLdouble centery, GLdouble centerz, 
		GLdouble upx, GLdouble upy, GLdouble upz );
};
#endif