package com.lanona.api.repository;

import com.lanona.api.entity.ChatThread;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface ChatThreadRepository extends JpaRepository<ChatThread, UUID> {

    List<ChatThread> findAllByOrderByUpdatedAtDesc();

    @Query("SELECT COALESCE(SUM(t.adminUnreadCount), 0) FROM ChatThread t")
    int sumAdminUnreadCount();
}
