//////////////////////////////////////////////////////////////////////////
//  CSkyBox类，天空盒载入和绘制
//
//  SkyBox.h: CSkyBox类的声明
//
//  Copy Rights Wonderful 2006
//////////////////////////////////////////////////////////////////////////

#ifndef __SKYBOX_H_INCLUDED__
#define __SKYBOX_H_INCLUDED__

#include "GL/glew.h"
//-------------------------------------------------------------------------------
// 盒子的面
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
// 天空盒
//-------------------------------------------------------------------------------
class CSkyBox
{
public:
	// 构造析构函数
	CSkyBox();  
	~CSkyBox();  

	// 设置位置和尺寸
	void SetPosAndSize(const float *pos, const float *size) { 
		for(int i = 0; i < 3; ++i){
			m_vPos[i] = pos[i];
			m_vSize[i] = size[i]; 
		}
	}

	// 设置一个置顶面的纹理图文件名，并载入
	bool LoadTexture(const GLuint* texture) { 
		for(int i = 0; i < 6; ++i){
			m_tTextures[i] = texture[i];
		}
		return true;
	}
	// 渲染天空盒子
	void Render();

private:
	GLuint		m_tTextures[6];	// 每面的纹理(0-5)
	float					m_vPos[3];         // 天空盒原点
	float					m_vSize[3];		// 天空盒尺寸
};

//-------------------------------------------------------------------------------
// 天空盒全局对象
//-------------------------------------------------------------------------------
extern CSkyBox g_SkyBox;

#endif

