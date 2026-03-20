package com.enterprise.csoms.service;

import com.enterprise.csoms.dto.response.RegionResponse;
import com.enterprise.csoms.dto.response.StoreResponse;
import com.enterprise.csoms.entity.Store;
import com.enterprise.csoms.entity.StoreRegion;
import com.enterprise.csoms.exception.ResourceNotFoundException;
import com.enterprise.csoms.repository.StoreRegionRepository;
import com.enterprise.csoms.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StoreService {

    private final StoreRepository       storeRepo;
    private final StoreRegionRepository regionRepo;

    @Transactional(readOnly = true)
    public List<RegionResponse> getAllRegions() {
        return regionRepo.findAll().stream().map(this::toRegionResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public RegionResponse getRegion(String regionCode) {
        return toRegionResponse(regionRepo.findByRegionCode(regionCode)
                .orElseThrow(() -> new ResourceNotFoundException("Region not found: " + regionCode)));
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> getStoresByRegion(String regionCode) {
        StoreRegion region = regionRepo.findByRegionCode(regionCode)
                .orElseThrow(() -> new ResourceNotFoundException("Region not found: " + regionCode));
        return storeRepo.findByRegionId(region.getId())
                .stream().map(this::toStoreResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> getAllStores() {
        return storeRepo.findAll().stream().map(this::toStoreResponse).collect(Collectors.toList());
    }

    private RegionResponse toRegionResponse(StoreRegion r) {
        return RegionResponse.builder()
                .externalId(r.getExternalId())
                .regionCode(r.getRegionCode())
                .regionName(r.getRegionName())
                .storeCount(r.getStoreCount())
                .distributionDc(r.getDistributionDc())
                .status(r.getStatus().name())
                .build();
    }

    private StoreResponse toStoreResponse(Store s) {
        return StoreResponse.builder()
                .externalId(s.getExternalId())
                .storeNumber(s.getStoreNumber())
                .storeName(s.getStoreName())
                .regionCode(s.getRegion().getRegionCode())
                .regionName(s.getRegion().getRegionName())
                .address(s.getAddress())
                .city(s.getCity())
                .stateCode(s.getStateCode())
                .zipCode(s.getZipCode())
                .status(s.getStatus().name())
                .build();
    }
}
