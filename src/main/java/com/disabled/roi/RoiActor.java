package com.disabled.roi;

/** ROI 요청을 한 사용자. loginId 는 임시 스냅샷 폴더(계정별 격리)에, name 은 이력(rh_u_name)에 쓴다. */
public final class RoiActor implements java.io.Serializable {
    private static final long serialVersionUID = 1L;

    public final String loginId;
    public final String name;

    public RoiActor(String loginId, String name) {
        this.loginId = loginId;
        this.name = name;
    }
}
