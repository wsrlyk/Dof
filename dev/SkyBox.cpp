#include "SkyBox.h"

#define GL_CLAMP_TO_EDGE	0x812F	

//-------------------------------------------------------------------------------
// ��պ�ȫ�ֶ���
//-------------------------------------------------------------------------------
CSkyBox g_SkyBox;

//-------------------------------------------------------------------------------
// ���캯��
//-------------------------------------------------------------------------------
CSkyBox::CSkyBox()
{

}

//-------------------------------------------------------------------------------
// ��������
//-------------------------------------------------------------------------------
CSkyBox::~CSkyBox()
{

}

//-------------------------------------------------------------------------------
// ����һ���ö��������ͼ�ļ�����������
//-------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
// ��Ⱦ��պ���
//-------------------------------------------------------------------------------
void CSkyBox::Render()
{
	float x = m_vPos[0];
	float y = m_vPos[1];
	float z = m_vPos[2];
	float width  = m_vSize[0];
	float height = m_vSize[1];
	float length = m_vSize[2];

	// This centers the sky box around (x, y, z)
	x = x - width  / 2;
	y = y - height / 2;
	z = z - length / 2;

	// ������ӳ��
	glEnable(GL_TEXTURE_2D);

	// ����
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_BACK]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);		

	// Assign the texture coordinates and vertices for the BACK Side
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x + width,	y,			z);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x + width,	y+ height,	z);
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x,			y + height, z); 
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x,			y,			z);

	glEnd();

	// ǰ��
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_FRONT]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);


	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);	

	// Assign the texture coordinates and vertices for the FRONT Side
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x,			y,			z + length);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x,			y + height, z + length); 
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x + width,	y + height, z + length);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x + width,	y,	z + length);
	glEnd();

	// Bind the BOTTOM texture of the sky map to the BOTTOM side of the box
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_BOTTOM]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);		

	// ����
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x,			y,			z);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x,			y,	z + length); 
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x + width,	y,	z + length);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x + width,	y,			z);
	glEnd();

	// ����
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_TOP]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);		

	// Assign the texture coordinates and vertices for the TOP Side
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x + width,	y + height,			z);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x + width,	y + height,	z + length);
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x,			y + height, z + length); 
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x,			y + height,			z);

	glEnd();

	// ����
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_LEFT]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);		

	// Assign the texture coordinates and vertices for the LEFT Side
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x,			y,			z+ length);		
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x,			y,		z );
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x,			y + height,			z); 
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x,			y + height,					z + length);	

	glEnd();

	// ����
	glBindTexture(GL_TEXTURE_2D, m_tTextures[ESIDE_RIGHT]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// Start drawing the side as a QUAD
	glBegin(GL_QUADS);		

	// Assign the texture coordinates and vertices for the RIGHT Side
	glTexCoord2f(0.0f, 1.0f); glVertex3f(x + width, y,	z );
	glTexCoord2f(1.0f, 1.0f); glVertex3f(x + width, y,			z + length);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(x + width, y + height,	z + length);
	glTexCoord2f(0.0f, 0.0f); glVertex3f(x + width, y + height,			z); 
	glEnd();
}
