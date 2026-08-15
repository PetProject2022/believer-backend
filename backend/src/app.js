import Fastify from 'fastify';
import multipart from '@fastify/multipart';
import fastifyStatic from '@fastify/static';
import { env } from './config/env.js';
import {
  ensureUploadsDirectories,
  maxMosqueImageUploadBytes,
  uploadsRootDir,
  uploadsUrlPrefix
} from './config/uploads.js';
import { securityPlugin } from './plugins/security.js';
import { authPlugin } from './plugins/auth.js';
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { accountGovernanceRoutes } from './routes/account-governance.js';
import { mosqueRoutes } from './routes/mosques.js';
import { bookmarkRoutes } from './routes/bookmarks.js';
import { notificationRoutes } from './routes/notifications.js';
import { businessListingsRoutes } from './routes/business-listings.js';
import { servicesRoutes } from './routes/services.js';
import { superAdminRoutes } from './routes/super-admin.js';
import { prayerTimesRoutes } from './routes/prayer-times.js';
import { createPrayerTimeService } from './services/prayer-times.js';
import { khutbahRoutes } from './routes/khutbah.js';
import {
  fetchServices,
  isKnownServiceCategory
} from './services/servicesService.js';
import { createLocationLookupService } from './services/location-lookup.js';
import { createEmailService } from './services/email/index.js';
import { createPushNotificationService } from './services/push-notifications.js';
import { ERROR_CODES } from './utils/error-codes.js';
import { HttpError, errorResponse } from './utils/http.js';

export function buildApp(options = {}) {
  const app = Fastify({
    logger: env.NODE_ENV !== 'test',
    trustProxy: env.TRUST_PROXY,
    requestIdHeader: 'x-request-id',
    genReqId: (request) => request.headers['x-request-id'] || undefined
  });

  app.addHook('onRequest', async (request, reply) => {
    reply.header('x-request-id', request.id);
  });

  app.decorate(
    'prayerTimeService',
    options.prayerTimeService ?? createPrayerTimeService()
  );
  app.decorate(
    'emailService',
    options.emailService ?? createEmailService()
  );
  app.decorate(
    'locationLookupService',
    options.locationLookupService ?? createLocationLookupService()
  );
  app.decorate(
    'pushNotificationService',
    options.pushNotificationService ?? createPushNotificationService()
  );
  app.decorate('servicesCatalog', options.servicesCatalog ?? {
    fetchServices,
    isKnownServiceCategory
  });

  app.addHook('onError', async (request, _reply, error) => {
    request.log.error(
      {
        reqId: request.id,
        method: request.method,
        url: request.url,
        errCode: error.code
      },
      'request failed'
    );
  });

  app.register(async (api) => {
    await ensureUploadsDirectories();
    await securityPlugin(api);
    await api.register(multipart, {
      limits: {
        files: 1,
        fileSize: maxMosqueImageUploadBytes
      }
    });
    await api.register(fastifyStatic, {
      root: uploadsRootDir,
      prefix: uploadsUrlPrefix
    });
    await healthRoutes(api);
    await authPlugin(api);
    await authRoutes(api);
    await accountGovernanceRoutes(api);
    await mosqueRoutes(api);
    await bookmarkRoutes(api);
    await notificationRoutes(api);
    await businessListingsRoutes(api);
    await superAdminRoutes(api);
    await servicesRoutes(api);
    await prayerTimesRoutes(api);
    await khutbahRoutes(api);
  });

  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof HttpError) {
      reply.status(error.statusCode).send(errorResponse(error));
      return;
    }

    if (error.validation) {
      reply.status(400).send(
        errorResponse(new HttpError(400, ERROR_CODES.validation, 'Invalid request payload', error.validation))
      );
      return;
    }

    app.log.error(error);
    reply
      .status(500)
      .send(errorResponse(new HttpError(500, ERROR_CODES.internalServerError, 'Internal server error')));
  });

  return app;
}
