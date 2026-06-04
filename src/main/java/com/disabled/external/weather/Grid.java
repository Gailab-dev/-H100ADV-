package com.disabled.external.weather;

/**
 * 기상청 단기예보 격자 좌표 (Lambert Conformal Conic).
 *
 * @param nx X축 격자 번호
 * @param ny Y축 격자 번호
 */
public record Grid(int nx, int ny) {
}
