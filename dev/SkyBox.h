//////////////////////////////////////////////////////////////////////////
//  CSkyBox�࣬��պ�����ͻ���
//
//  SkyBox.h: CSkyBox�������
//
//  Copy Rights Wonderful 2006
//////////////////////////////////////////////////////////////////////////

#ifndef __SKYBOX_H_INCLUDED__
#define __SKYBOX_H_INCLUDED__

#include "GL/glew.h"
//-------------------------------------------------------------------------------
// ���ӵ���
//-------------------------------------------------------------------------------
enum ESkyBoxSides 
{
	ESIDE_TOP = 0,
	ESIDE_BOTTOM,
	ESIDE_LEFT,
	ESIDE_RIGHT,
	ESIDE_FRONT,
	ESIDE_BACK,
	ESIDE_MAX
};

//-------------------------------------------------------------------------------
// ��պ�
//-------------------------------------------------------------------------------
class CSkyBox
{
public:
	// ������������
	CSkyBox();  
	~CSkyBox();  

	// ����λ�úͳߴ�
	void SetPosAndSize(const float *pos, const float *size) { 
		for(int i = 0; i < 3; ++i){
			m_vPos[i] = pos[i];
			m_vSize[i] = size[i]; 
		}
	}

	// ����һ���ö��������ͼ�ļ�����������
	bool LoadTexture(const GLuint* texture) { 
		for(int i = 0; i < 6; ++i){
			m_tTextures[i] = texture[i];
		}
		return true;
	}
	// ��Ⱦ��պ���
	void Render();

private:
	GLuint		m_tTextures[6];	// ÿ�������(0-5)
	float					m_vPos[3];         // ��պ�ԭ��
	float					m_vSize[3];		// ��պгߴ�
};

//-------------------------------------------------------------------------------
// ��պ�ȫ�ֶ���
//-------------------------------------------------------------------------------
extern CSkyBox g_SkyBox;

#endif

