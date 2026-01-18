package com.anatoliy.ServiceA.repository;

import com.anatoliy.ServiceA.entity.ProcessingLog;
import lombok.NonNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProcessingLogRepository extends JpaRepository<@NonNull ProcessingLog,@NonNull UUID> {
}