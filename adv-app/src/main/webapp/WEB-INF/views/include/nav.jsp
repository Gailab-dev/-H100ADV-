<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<nav id="sidebarMenu" class="col-md-3 col-lg-2 d-md-block bg-light sidebar collapse">
   <div class="sidebar-sticky pt-3">
     <h6 class="sidebar-heading d-flex justify-content-between align-items-center px-3 mt-2 mb-1 ">
       <span>회원관리</span>
     </h6>
     <ul class="nav flex-column border-bottom">
       
       <li class="nav-item">
         <a class="nav-link" href="member_request.do">
           회원가입관리
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link" href="part.do">
           부서 등록
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link" href="position.do">
           직급 등록
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link " href="user.do">
           사용자 관리
         </a>
       </li>
       
     </ul>
     <h6 class="sidebar-heading d-flex justify-content-between align-items-center px-3 mt-2 mb-1 ">
       <span>민원 관리</span>
     </h6>
     <ul class="nav flex-column border-bottom">
       
       <li class="nav-item">
         <a class="nav-link" href="mw_list.do">
           전체민원
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link" href="mw_delete.do">
           삭제민원
         </a>
       </li>
     </ul>
     <h6 class="sidebar-heading d-flex justify-content-between align-items-center px-3 mt-2 mb-1 ">
       <span>접근 관리</span>
     </h6>
     <ul class="nav flex-column border-bottom">
       
       <li class="nav-item">
         <a class="nav-link" href="mw_login_ip.do">
           로그인 IP 정보
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link" href="mw_admin_setting.do">
           관리자 설정
         </a>
       </li>
     </ul>
     <h6 class="sidebar-heading d-flex justify-content-between align-items-center px-3 mt-2 mb-1 ">
       <span>게시판 관리</span>
     </h6>
     <ul class="nav flex-column border-bottom">
       
       <li class="nav-item">
         <a class="nav-link" href="mw_notice_list.do">
           공지사항 관리
         </a>
       </li>
       <li class="nav-item">
         <a class="nav-link" href="mw_archive_list.do">
           자료실 관리
         </a>
       </li>
     </ul>
   </div>
 </nav>