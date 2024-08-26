import {instance} from './Axios';

// 获取验证码
export function sendCode(phone: string) {
  return instance.get('/word/user/code', { params: { phone: phone } });
}

// 登录
interface LoginData {
  phone: string;
  code: string;
}
export function login(phone: string, code: string) {
  const data: LoginData = {
    phone: phone,
    code: code
  };
  return instance.post('/word/user/login', data);
}

// 打卡
export interface createPostModel {
  rightCount: number,
  answeredCount: number,
  timeUsed: number
}
export function createPost(post: createPostModel) {
  return instance.post('/word/post/create', post)
}

// 打卡列表
export function getAllPost(page: number, size: number) {
  return instance.get('/word/post/getAll', { params: { page: page, size: size } })
}

//点赞
export function like(postId: number) {
  return instance.get('/word/like/create', { params: { postId: postId } })
}

//取消点赞
export function cancelLike(postId: number) {
  return instance.get('/word/like/cancel', { params: { postId: postId } })
}

//获取登录用户信息
export function info() {
  return instance.get('/word/user/info')
}

//获取我的登录打卡记录
export function getMyPost(page: number, size: number) {
  return instance.get('/word/post/getMine', { params: { page: page, size: size } })
}


