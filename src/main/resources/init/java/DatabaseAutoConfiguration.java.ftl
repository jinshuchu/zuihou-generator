package ${packageBase}.config.datasource;


import cn.hutool.core.util.ArrayUtil;
import com.alibaba.druid.spring.boot.autoconfigure.DruidDataSourceBuilder;
import com.baomidou.mybatisplus.autoconfigure.ConfigurationCustomizer;
import com.baomidou.mybatisplus.autoconfigure.MybatisPlusProperties;
import com.baomidou.mybatisplus.autoconfigure.MybatisPlusPropertiesCustomizer;
import com.github.zuihou.database.datasource.BaseDatabaseConfiguration;
import com.github.zuihou.database.properties.DatabaseProperties;
import com.p6spy.engine.spy.P6DataSource;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.mapping.DatabaseIdProvider;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.scripting.LanguageDriver;
import org.apache.ibatis.session.ExecutorType;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.type.TypeHandler;
import org.mybatis.spring.SqlSessionTemplate;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.aop.Advisor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.ResourceLoader;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.interceptor.TransactionInterceptor;

import javax.sql.DataSource;
import java.util.List;

/**
 *
 * ${description}-事务 & 连接 & mybatis &  mp 等配置
 *
 * @author ${author}
 * @date ${date}
 */
@Configuration
@Slf4j
@MapperScan(
        basePackages = { "${packageBaseParent}", }, annotationClass = Repository.class,
        sqlSessionFactoryRef = ${service}DatabaseAutoConfiguration.DATABASE_PREFIX + "SqlSessionFactory")
@EnableConfigurationProperties({MybatisPlusProperties.class, DatabaseProperties.class})
public class ${service}DatabaseAutoConfiguration extends BaseDatabaseConfiguration {
    /**
     * 每个数据源配置不同即可
     */
    final static String DATABASE_PREFIX = "master";

    public ${service}DatabaseAutoConfiguration(MybatisPlusProperties properties,
                                              DatabaseProperties databaseProperties,
                                              ObjectProvider${r"<Interceptor[]>"} interceptorsProvider,
                                              ObjectProvider${r"<TypeHandler[]>"} typeHandlersProvider,
                                              ObjectProvider${r"<LanguageDriver[]>"} languageDriversProvider,
                                              ResourceLoader resourceLoader,
                                              ObjectProvider${r"<DatabaseIdProvider>"} databaseIdProvider,
                                              ObjectProvider${r"<List<ConfigurationCustomizer>>"} configurationCustomizersProvider,
                                              ObjectProvider${r"<List<MybatisPlusPropertiesCustomizer>>"} mybatisPlusPropertiesCustomizerProvider,
                                              ApplicationContext applicationContext) {
        super(properties, databaseProperties, interceptorsProvider, typeHandlersProvider,
                languageDriversProvider, resourceLoader, databaseIdProvider,
                configurationCustomizersProvider, mybatisPlusPropertiesCustomizerProvider, applicationContext);
    }

    @Bean(DATABASE_PREFIX + "SqlSessionTemplate")
    public SqlSessionTemplate getSqlSessionTemplate(@Qualifier(DATABASE_PREFIX + "SqlSessionFactory") SqlSessionFactory sqlSessionFactory) {
        ExecutorType executorType = this.properties.getExecutorType();
        if (executorType != null) {
            return new SqlSessionTemplate(sqlSessionFactory, executorType);
        } else {
            return new SqlSessionTemplate(sqlSessionFactory);
        }
    }

    /**
     * 数据源信息
     *
     * @return
     */
    @Primary
    @Bean(name = DATABASE_PREFIX + "DruidDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.druid")
    public DataSource druidDataSource() {
        return DruidDataSourceBuilder.create().build();
    }

    @Bean(name = DATABASE_PREFIX + "DataSource")
    public DataSource dataSource(@Qualifier(DATABASE_PREFIX + "DruidDataSource") DataSource dataSource) {
        if (ArrayUtil.contains(DEV_PROFILES, this.profiles)) {
            return new P6DataSource(dataSource);
        } else {
            return dataSource;
        }
    }

    /**
     * mybatis Sql Session 工厂
     *
     * @return
     * @throws Exception
     */
    @Bean(DATABASE_PREFIX + "SqlSessionFactory")
    public SqlSessionFactory getSqlSessionFactory(@Qualifier(DATABASE_PREFIX + "DataSource") DataSource dataSource) throws Exception {
        return super.sqlSessionFactory(dataSource);
    }

    /**
     * 数据源事务管理器
     *
     * @return
     */
    @Bean(name = DATABASE_PREFIX + "TransactionManager")
    public DataSourceTransactionManager dsTransactionManager(@Qualifier(DATABASE_PREFIX + "DataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    /**
     * 事务拦截器
     *
     * @param transactionManager
     * @return
     */
    @Bean(DATABASE_PREFIX + "TransactionInterceptor")
    public TransactionInterceptor transactionInterceptor(@Qualifier(DATABASE_PREFIX + "TransactionManager") PlatformTransactionManager transactionManager) {
        return new TransactionInterceptor(transactionManager, this.transactionAttributeSource());
    }

    /**
     * 事务 Advisor
     *
     * @param transactionManager
     * @return
     */
    @Bean(DATABASE_PREFIX + "Advisor")
    public Advisor getAdvisor(@Qualifier(DATABASE_PREFIX + "TransactionManager") PlatformTransactionManager transactionManager, @Qualifier(DATABASE_PREFIX + "TransactionInterceptor") TransactionInterceptor ti) {
        return super.txAdviceAdvisor(ti);
    }

}
