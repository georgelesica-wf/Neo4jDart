library session_spec;

import 'package:unittest/unittest.dart' show unittestConfiguration;
import '../helpers.dart';
import '../helpers/domain.dart';

main() {
  unittestConfiguration.timeout = new Duration(seconds: 10);
  var db = setUp();

  describe('DbSession', () {
    DbSession session;
    Movie avatar, cars, theGreenMile;

    beforeEach(() async {
      session = new DbSession(db);
      var movieRepository = new MovieRepository(session);

      cars = new Movie()
        ..name = 'Cars'
        ..year = 2006;

      await setUpTestData();

      avatar = await movieRepository.find({'name': 'Avatar'});
      theGreenMile = await movieRepository.find({'name': 'The Green Mile'});
    });
    afterEach(cleanUpTestData);

    it('should send an event after a node is created', () {
      session.onCreated.listen(expectAsync((node) {
        expect(node.id).toBeNotNull();
        expect(node.labels).toEqual(['Movie']);
        expect(node.entity).toBe(cars);
      }));

      session..store(cars)..saveChanges();
    });

    it('should send an event after a node is updated', () {
      session.onUpdated.listen(expectAsync((node) {
        expect(node.id).toEqual(avatar.id);
        expect(node.labels).toEqual(['Movie']);
        expect(node.entity).toBe(avatar);
      }));

      avatar.name = 'Avatar 2';
      session..store(avatar)..saveChanges();
    });

    it('should send an event after a node is deleted', () {
      session.onDeleted.listen(expectAsync((node) {
        expect(node.id).toEqual(theGreenMile.id);
        expect(node.labels).toEqual(['SpecificMovie', 'Movie']);
        expect(node.entity).toBe(theGreenMile);
      }));

      session..delete(theGreenMile)..saveChanges();
    });

    it('should send an event after a node is deleted with relations', () {
      session.onDeleted.listen(expectAsync((node) {
        expect(node.id).toEqual(avatar.id);
        expect(node.labels).toEqual(['Movie']);
        expect(node.entity).toBe(avatar);
      }));

      session..delete(avatar, deleteRelations: true)..saveChanges();
    });

    it('should close all streams on dispose', () async {
      session.onCreated.listen((_) {}, onDone: expectAsync(() {}));
      session.onUpdated.listen((_) {}, onDone: expectAsync(() {}));
      session.onDeleted.listen((_) {}, onDone: expectAsync(() {}));

      session.dispose();
    });

    it('should not allow interactions after dispose', () {
      session.dispose();

      expect(session.isDisposed).toBeTrue();

      expect(() => session.store(cars)).toThrowWith(
          type: StateError,
          message: 'The session have been disposed'
      );
      expect(() => session.delete(theGreenMile)).toThrowWith(
          type: StateError,
          message: 'The session have been disposed'
      );
      session.saveChanges().catchError(expectAsync((e) {
        expect(e).toBeA(StateError);
        expect(e.message).toEqual('The session have been disposed');
      }));
    });
  });
}
